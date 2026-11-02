# Rules (93G)

The rules for this repo's part of the alignment, then the learned rules. Read before every unit. Any tool adds a learned
rule in the same commit as the fix that confirmed it, newest last: `- YYYY-MM-DD <area>: <rule>. (<evidence>)`.

## Who decides what (all games)

| Category | Decided by |
|---|---|
| Name of a routine several games share | the earliest game that has it (92G is the root); a fix goes to the earliest repo first, then down the lineage |
| Name of a feature new in year N | that year's Genesis game (94G for 94S and 94PC, 95G for 95S and 95PC) |
| Name of a platform-only job | the earlier repo on that platform (93S for 94S, 94PC for 95PC), else what the code does |
| Same name, different job | the earlier meaning keeps the name |
| Top folder or file | the same-year Genesis file |
| RAM order | the merged order (92G, 93G, 94G, 93S, 94S, then 95G, 96G) |
| Data, assets, banks | the earlier repo on the same platform |
| Order inside a file | ROM order (the report re-sorts for display) |
| History | `docs/name_map.csv` only, never source comments |

## This repo

- Names: 92G is the root. A 93G name that is inaccurate is fixed here first, then carried to 93S, 94G and 94S.
- Layout: keep the 92G file shape (`hockey93.asm` holds what 94G later split into setup, collide, replay and others). Do not split it.
- This repo is the reference for 93S. A 93S routine sits in the folder of its 93G module.

## Learned

