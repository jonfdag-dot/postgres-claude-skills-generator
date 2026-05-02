-- ============================================================================
-- script_id: inventory-on-hand-snapshot
--
-- Latest snapshot of qty_on_hand per (warehouse × SKU). Snapshot
-- semantics: NEVER SUM across days. ROW_NUMBER picks the latest
-- snapshot per partition.

WITH latest_snapshots AS (
  SELECT
    inv.warehouse_id,
    inv.sku_id,
    inv.qty_on_hand,
    inv.snapshot_ts,
    ROW_NUMBER() OVER (
      PARTITION BY inv.warehouse_id, inv.sku_id
      ORDER BY inv.snapshot_ts DESC
    ) AS rn
  FROM public.inventory_snapshots inv
  WHERE inv.qty_on_hand > 0
)
SELECT
  ls.warehouse_id,
  ls.sku_id,
  k.sku_name,
  ls.qty_on_hand,
  ls.snapshot_ts
FROM latest_snapshots ls
JOIN public.skus                k ON k.sku_id = ls.sku_id
JOIN public.warehouse_locations w ON w.warehouse_id = ls.warehouse_id
WHERE ls.rn = 1
ORDER BY ls.warehouse_id, ls.qty_on_hand DESC;
