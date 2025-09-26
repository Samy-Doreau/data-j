with business_addresses as (
    select * from {{ ref('business_addresses') }}
)

select 
    business_address,
    postcode,
    left(postcode, 4) as postcode_three_letter,
    count(distinct business_name) as tenant_count
from business_addresses
group by 1, 2
