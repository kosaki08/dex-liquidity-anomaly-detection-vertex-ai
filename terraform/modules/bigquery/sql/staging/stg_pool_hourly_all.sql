WITH
  parsed_data AS (
    -- Uniswap V3
    SELECT
      'uniswap_v3' as dex_protocol,
      pool_id,
      hour_ts,
      CAST(
        JSON_EXTRACT_SCALAR (raw, '$.volumeUSD') AS FLOAT64
      ) as volume_usd,
      CAST(
        JSON_EXTRACT_SCALAR (raw, '$.totalValueLockedUSD') AS FLOAT64
      ) as tvl_usd,
      CAST(
        JSON_EXTRACT_SCALAR (raw, '$.totalValueLockedUSD') AS FLOAT64
      ) as liquidity,
      CAST(JSON_EXTRACT_SCALAR (raw, '$.txCount') AS INT64) as tx_count,
      load_ts
    FROM
      `${project_id}.${raw_dataset}.pool_hourly_uniswap_v3`
    WHERE
      DATE (hour_ts) >= DATE_SUB (CURRENT_DATE(), INTERVAL 90 DAY)
    UNION ALL
    -- Sushiswap V3
    SELECT
      'sushiswap_v3' as dex_protocol,
      pool_id,
      hour_ts,
      CAST(
        JSON_EXTRACT_SCALAR (raw, '$.volumeUSD') AS FLOAT64
      ) as volume_usd,
      CAST(
        JSON_EXTRACT_SCALAR (raw, '$.totalValueLockedUSD') AS FLOAT64
      ) as tvl_usd,
      CAST(
        JSON_EXTRACT_SCALAR (raw, '$.liquidityUSD') AS FLOAT64
      ) as liquidity,
      CAST(
        JSON_EXTRACT_SCALAR (raw, '$.hourlyTxns') AS INT64
      ) as tx_count,
      load_ts
    FROM
      `${project_id}.${raw_dataset}.pool_hourly_sushiswap_v3`
    WHERE
      DATE (hour_ts) >= DATE_SUB (CURRENT_DATE(), INTERVAL 90 DAY)
  )
SELECT
  dex_protocol,
  pool_id,
  hour_ts,
  volume_usd,
  tvl_usd,
  liquidity,
  tx_count,
  -- データ品質チェック
  CASE
    WHEN volume_usd < 0
    OR tvl_usd < 0 THEN TRUE
    ELSE FALSE
  END as has_negative_values,
  load_ts
FROM
  parsed_data