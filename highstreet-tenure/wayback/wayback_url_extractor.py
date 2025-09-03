#!/usr/bin/env python3
import argparse, csv, re, time, os, random
import requests
from bs4 import BeautifulSoup
from urllib.parse import urljoin, urlparse
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

CDX_ENDPOINT = "https://web.archive.org/cdx/search/cdx"
WAYBACK_PREFIX = "https://web.archive.org/web"
DEFAULT_USER_AGENT = "wayback-harvester/1.1"


def create_session(max_retries=5, backoff_factor=0.5, user_agent=DEFAULT_USER_AGENT):
    retry = Retry(
        total=max_retries,
        read=max_retries,
        connect=max_retries,
        status=max_retries,
        backoff_factor=backoff_factor,
        status_forcelist=[429, 500, 502, 503, 504],
        allowed_methods=frozenset(["HEAD", "GET"]),
        raise_on_status=False,
        respect_retry_after_header=True,
    )
    adapter = HTTPAdapter(max_retries=retry)
    session = requests.Session()
    session.mount("https://", adapter)
    session.mount("http://", adapter)
    session.headers.update({"User-Agent": user_agent})
    return session


def list_snapshots(session, target_url, from_year=None, to_year=None, limit=None, timeout=30):
    # Exact URL snapshots; don't collapse so you keep each day/version
    params = {
        "url": target_url,
        "output": "json",
        "fl": "timestamp,original,statuscode,mimetype",
        # collapse: omit to keep all versions; you can add "collapse=digest" to keep 1 per unique content
    }
    if from_year:
        params["from"] = str(from_year)
    if to_year:
        params["to"] = str(to_year)

    r = session.get(CDX_ENDPOINT, params=params, timeout=timeout)
    r.raise_for_status()
    js = r.json()
    rows = js[1:] if js and isinstance(js, list) else []  # skip header
    if limit:
        rows = rows[:limit]
    return [(ts, orig, code, mt) for ts, orig, code, mt in rows]


def fetch_archived_html(session, timestamp, original_url, sleep=0.5, jitter=0.5, timeout=30):
    # Try with id_ first (preserves original resource), then fall back to normal replay
    archived_id = f"{WAYBACK_PREFIX}/{timestamp}id_/{original_url}"
    archived_plain = f"{WAYBACK_PREFIX}/{timestamp}/{original_url}"

    # Helper to honor polite pacing with jitter
    def _sleep():
        extra = max(0.0, sleep * jitter)
        time.sleep(sleep + random.uniform(0.0, extra))

    try:
        r = session.get(archived_id, timeout=timeout)
        _sleep()
        if r.status_code == 200:
            return r.text, archived_id
    except requests.exceptions.RequestException as e:
        # Fall through to try plain
        pass

    try:
        r = session.get(archived_plain, timeout=timeout)
        _sleep()
        if r.status_code == 200:
            return r.text, archived_plain
    except requests.exceptions.RequestException as e:
        return None, archived_plain

    return None, archived_plain


def extract_links(html, base="https://www.stalbans.gov.uk/", pattern=r"\.(?:xls|xlsx)$", absolute=True):
    soup = BeautifulSoup(html, "html.parser")
    hrefs = set()
    for a in soup.select("a[href]"):
        href = a["href"].strip()
        if pattern and not re.search(pattern, href, flags=re.IGNORECASE):
            continue
        if absolute:
            # Normalize to absolute original URL (not the wayback URL)
            href = urljoin(base, href)
        hrefs.add(href)
    return sorted(hrefs)


def write_rows_incremental(csv_path, rows, write_header_if_needed=True):
    if not rows:
        return
    fieldnames = [
        "snapshot_timestamp",
        "page_archived_url",
        "found_href",
        "wayback_download_url",
    ]
    file_exists = os.path.exists(csv_path)
    with open(csv_path, "a", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        if write_header_if_needed and not file_exists:
            writer.writeheader()
        writer.writerows(rows)


def main():
    ap = argparse.ArgumentParser(description="Harvest links from all Wayback snapshots of a URL.")
    ap.add_argument("--url", required=True, help="The original page URL to enumerate in Wayback.")
    ap.add_argument("--from-year", type=int, default=None, help="Restrict snapshots from this year (e.g., 2018).")
    ap.add_argument("--to-year", type=int, default=None, help="Restrict snapshots to this year.")
    ap.add_argument("--limit", type=int, default=None, help="Limit number of snapshots (debug).")
    ap.add_argument("--regex", default=r"\.(?:xls|xlsx)$", help="Regex for links to extract (default: Excel).")
    ap.add_argument("--out", default="wayback_links.csv", help="Output CSV file.")
    ap.add_argument("--sleep", type=float, default=0.7, help="Base seconds to sleep between requests (default: 0.7).")
    ap.add_argument("--jitter", type=float, default=0.5, help="Jitter fraction added to sleep (default: 0.5 adds up to +50%).")
    ap.add_argument("--timeout", type=float, default=30.0, help="Per-request timeout seconds (default: 30).")
    ap.add_argument("--retries", type=int, default=5, help="Max retries on transient errors (default: 5).")
    ap.add_argument("--backoff", type=float, default=0.5, help="Exponential backoff factor for retries (default: 0.5).")
    ap.add_argument(
        "--flush-every", type=int, default=1, help="Write to CSV every N snapshots (default: 1)."
    )
    args = ap.parse_args()

    # Make a reasonable base for absolute URL joins
    parsed = urlparse(args.url)
    base = f"{parsed.scheme}://{parsed.netloc}/"

    session = create_session(max_retries=args.retries, backoff_factor=args.backoff)

    try:
        snapshots = list_snapshots(
            session,
            args.url,
            args.from_year,
            args.to_year,
            args.limit,
            timeout=args.timeout,
        )
    except requests.exceptions.RequestException as e:
        print(f"Failed to list snapshots: {e}")
        return

    if not snapshots:
        print("No snapshots found.")
        return

    # Deduplicate identical (timestamp, found_href) pairs across the run
    seen = set()
    buffer_rows = []

    for idx, (ts, orig, code, mt) in enumerate(snapshots, start=1):
        try:
            html, archived_page = fetch_archived_html(
                session, ts, orig, sleep=args.sleep, jitter=args.jitter, timeout=args.timeout
            )
        except requests.exceptions.RequestException as e:
            print(f"[err] {ts}: {e}")
            continue

        if not html:
            print(f"[skip] {ts} (failed to fetch archived page)")
            continue

        links = extract_links(html, base=base, pattern=args.regex, absolute=True)
        found_count = 0
        for href in links:
            # Build a Wayback download URL for the found file at THIS snapshot timestamp
            wb_download = f"{WAYBACK_PREFIX}/{ts}id_/{href}"
            key = (ts, href)
            if key in seen:
                continue
            seen.add(key)
            buffer_rows.append(
                {
                    "snapshot_timestamp": ts,
                    "page_archived_url": archived_page,
                    "found_href": href,
                    "wayback_download_url": wb_download,
                }
            )
            found_count += 1

        print(f"[ok] {ts}: found {found_count} links")

        # Incremental write
        if args.flush_every > 0 and (idx % args.flush_every == 0) and buffer_rows:
            write_rows_incremental(args.out, buffer_rows, write_header_if_needed=True)
            buffer_rows = []

    # Final flush
    if buffer_rows:
        write_rows_incremental(args.out, buffer_rows, write_header_if_needed=not os.path.exists(args.out))

    print(f"Done. Output: {args.out}")


if __name__ == "__main__":
    main()





