{% macro normalize_business_name(name_expr) %}
    regexp_replace(
        lower(
            trim(
                regexp_replace(                   -- collapse multiple spaces
                    regexp_replace(               -- remove non-alphanumeric (keep space)
                        regexp_replace(           -- replace "&" with "and"
                            {{ name_expr }},
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
{% endmacro %}


