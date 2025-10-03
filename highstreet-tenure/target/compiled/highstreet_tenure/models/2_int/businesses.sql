

with businesses_new as (
    select distinct primary_liable_party_name as business_name from "highstreet"."analytics_analytics"."stg_new_businesses"

),

businesses_accounts_closed as (
    select distinct primary_liable_party_name as business_name from "highstreet"."analytics_analytics"."stg_accounts_closed"

),

businesses_accounts_no_relief as (
    select distinct primary_liable_party_name as business_name from "highstreet"."analytics_analytics"."stg_accounts_no_relief"

),

businesses_accounts_relief as (
    select distinct primary_liable_party_name as business_name from "highstreet"."analytics_analytics"."stg_accounts_relief"

),


combined_businesses as (

    select business_name from businesses_new
    union 
    select business_name from businesses_accounts_closed
    union 
    select business_name from businesses_accounts_no_relief
    union 
    select business_name from businesses_accounts_relief
),

normalized as (
    select 
        
    regexp_replace(
        lower(
            trim(
                regexp_replace(                   -- collapse multiple spaces
                    regexp_replace(               -- remove non-alphanumeric (keep space)
                        regexp_replace(           -- replace "&" with "and"
                            business_name,
                            '&', 'and', 'gi'
                        ),
                        '[^a-zA-Z0-9 ]', '', 'g'
                    ),
                    '\\s+', ' ', 'g'
                )
            )
        ),
        '^ta ', '', 'g'
    )
 as name_norm,
        business_name
    from combined_businesses
)

select  
business_name,
 case
    -- Supermarkets & large grocery
    when name_norm ~* '(tesco|sainsbury|asda|morrisons|waitrose|iceland|aldi|lidl|co\s*op|cooperative|marks and spencer|m\s*&?\s*s|mands\s*food|mands)' then 'Supermarket'

    -- Convenience, newsagents & off-licence chains
    when name_norm ~* '(off\s*licen|convenience|corner shop|newsagent|costcutter|spar|londis|premier|best one|one stop|nisa|mace|bargain booze)' then 'Convenience & newsagent'

    -- Pharmacy (before health & beauty to prioritise Boots, etc.)
    when name_norm ~* '(pharmacy|chemist|boots(?!.*optician)|lloyds\s*pharmacy|well\s*pharmacy|numark)' then 'Pharmacy'

    -- Opticians
    when name_norm ~* '(optician|specsavers|vision express|scrivens|boots\s*optician)' then 'Optician'

    -- Hair & beauty split
    when name_norm ~* '(barber|barbers|barber shop)' then 'Barber'
    when name_norm ~* '(nail|beauty|spa|tanning|aesthetics|lash|brow)' then 'Beauty salon'
    when name_norm ~* '(hair|hairdresser|hairdressing|salon)' then 'Hair salon'

    -- Coffee shops & cafes
    when name_norm ~* '(costa|starbucks|caffe\s*nero|nero|pret\s*a\s*manger|tim\s*hortons|coffee|espresso|cafe|tea\s*room|tearoom|bistro|brasserie)' then 'Cafe / coffee shop'

    -- Bakeries & sandwich
    when name_norm ~* '(bakery|patisserie|baguette|greggs|cake shop|cupcake|patisserie valerie)' then 'Bakery & sandwich'

    -- Fast food & national QSR chains
    when name_norm ~* '(mcdonald|kfc|burger\s*king|subway|domino|pizza\s*hut|papa\s*john|five\s*guys|shake\s*shack|chicken\s*cottage|morleys|favorite\s*chicken)' then 'Fast food / takeaway'

    -- Fish & chips and generic takeaways
    when name_norm ~* '(fish\s*(and|\&)\s*chips|chippy|chip shop|kebab|peri\s*peri|fried\s*chicken|takeaway|noodle|ramen|sushi|shawarma|doner|curry|tandoori|balti|pizzeria)' then 'Fast food / takeaway'

    -- Restaurants (casual & full service)
    when name_norm ~* '(restaurant|ristorante|trattoria|grill|steakhouse|thai|indian|chinese|italian|mexican|tapas|lebanese|turkish|korean|brazilian|argentinian|ethiopian)' then 'Restaurant'

    -- Pubs, bars & nightlife
    when name_norm ~* '(pub|tavern|bar|inn|wetherspoon|wetherspoons|jd\s*wetherspoon|taproom|ale\s*house|brewery|nightclub|club\b|lounge)' then 'Pub / bar'

    -- Banks & building societies
    when name_norm ~* '(bank|lloyds|hsbc|natwest|barclays|santander|tsb|halifax|nationwide|virgin\s*money|metro\s*bank|yorkshire\s*bank|clydesdale\s*bank)' then 'Bank / building society'

    -- Post office
    when name_norm ~* '(post\s*office|postoffice)' then 'Post office'

    -- Estate & letting agents
    when name_norm ~* '(estate\s*agent|lettings|letting\s*agent|property\s*agent|savills|foxtons|haart|winkworth|connells|leaders|hunters|countrywide|purplebricks)' then 'Estate & letting agent'

    -- Charity shops
    when name_norm ~* '(oxfam|barnardo|british\s*heart\s*foundation|cancer\s*research|sue\s*ryder|mind\b|salvation\s*army|ymca|age\s*uk|shaw\s*trust)' then 'Charity shop'

    -- Betting shops
    when name_norm ~* '(ladbrokes|william\s*hill|betfred|coral|paddy\s*power|bookmaker|betting\s*shop)' then 'Betting shop'

    -- Electronics & mobile
    when name_norm ~* '(currys|pc\s*world|carphone|ee\b|vodafone|o2\b|three\b|3\s*store|apple\s*store|samsung\s*store|fone|phone\s*shop)' then 'Electronics & mobile'

    -- Computers / tech repair
    when name_norm ~* '(computer|laptop|it\s*service|tech\s*repair|phone\s*repair|ifix|repair\s*centre)' then 'Repair services'

    -- Jewellers
    when name_norm ~* '(jewell?er|goldsmith|pandora|ernest\s*jones|h\s*samuel|beaverbrooks)' then 'Jeweller'

    -- Clothing & fashion
    when name_norm ~* '(primark|h\s*&?\s*m\b|next\b|zara|uniqlo|river\s*island|new\s*look|topshop|burton|dorothy\s*perkins|jack\s*wills|fat\s*face|white\s*stuff|joules|superdry|all\s*saints|tk\s*maxx|tkmaxx)' then 'Clothing & fashion'

    -- Shoes & footwear
    when name_norm ~* '(clarks|schuh|foot\s*locker|deichmann|office\s*shoes|kurt\s*geiger|timberland)' then 'Shoes & footwear'

    -- Sports & outdoors
    when name_norm ~* '(sports\s*direct|jd\s*sports|decathlon|go\s*outdoors)' then 'Sports & outdoors'

    -- Books & stationery
    when name_norm ~* '(wh\s*smith|whsmith|waterstones|bookshop|book\s*store|ryman|paperchase|the\s*works|stationery)' then 'Books & stationery'

    -- Home, DIY & hardware
    when name_norm ~* '(wilko|wilkinson|b\s*&?\s*m\b|home\s*bargains|the\s*range|b\s*&?\s*q\b|wickes|screwfix|toolstation|homebase|ikea|robert\s*dyas|hardware|ironmonger)' then 'Home & DIY'

    -- Furniture & homeware
    when name_norm ~* '(furniture|sofa|bensons\s*for\s*beds|dfs\b|dreams\b|wren\s*kitchen|magnet\s*kitchen|bathstore)' then 'Furniture & homeware'

    -- Garden & florists
    when name_norm ~* '(garden\s*centre|gardencentre|garden\b|florist|flowers|bloom|interflora)' then 'Garden & florist'

    -- Pets & vets
    when name_norm ~* '(pets\s*at\s*home|pet\s*shop|aquatic|veterinar|\bvet\b|groomer|grooming|kennel|cattery)' then 'Pets & vets'

    -- Automotive services
    when name_norm ~* '(garage\b|mot\b|tyres?|autocent(re|er)|halfords|kwik\s*fit|kwikfit|ats\s*euromaster|euro\s*car\s*parts|car\s*wash|valet|valeting|dealership|showroom)' then 'Automotive services'

    -- Travel agents
    when name_norm ~* '(travel\s*agent|tui\b|thomas\s*cook|trailfinders|flight\s*centre|hays\s*travel)' then 'Travel agent'

    -- Dry cleaning & laundry
    when name_norm ~* '(dry\s*clean|launderette|laundrette|laundry|wash\s*and\s*fold|ironing)' then 'Dry cleaning & laundry'

    -- Tailor & alterations
    when name_norm ~* '(tailor|alteration|seamstress|bespoke\s*suit)' then 'Tailor & alterations'

    -- Key cutting, shoe repair & photo
    when name_norm ~* '(timpson|shoe\s*repair|key\s*cut|snappy\s*snaps|photo\s*centre|photograph)' then 'Key cutting & photo'

    -- Education & childcare
    when name_norm ~* '(nursery|pre\s*school|preschool|childcare|day\s*nursery|montessori|tuition|tutor|kumon)' then 'Education & childcare'

    -- Medical & dental
    when name_norm ~* '(dental|dentist|orthodontist|gp\s*surgery|medical\s*centre|clinic|physio|physiotherapy|chiropractic|osteopath|podiatr|dermatolog)' then 'Medical & dental'

    -- Hotels & accommodation
    when name_norm ~* '(hotel|guest\s*house|bed\s*and\s*breakfast|b\s*&?\s*b\b|bnb\b|hostel|premier\s*inn|travelodge|ibis|marriott|hilton|holiday\s*inn)' then 'Hotel & accommodation'

    -- Leisure & entertainment
    when name_norm ~* '(cinema|theatre|theater|bowling|escape\s*room|arcade|bingo)' then 'Leisure & entertainment'

    else 'Unclassified'
 end as business_category
from normalized