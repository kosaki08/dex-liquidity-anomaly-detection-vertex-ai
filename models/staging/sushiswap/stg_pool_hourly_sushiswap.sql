{{ config(materialized='view') }}

-- Sushiswap V3 用
{{ pool_hourly_base('pool_hourly_sushiswap_v3') }}
