{{ config(materialized='view') }}

-- Uniswap V3 用
{{ pool_hourly_base('pool_hourly_uniswap_v3') }}
