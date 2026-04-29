# Tommy Boosting Install
1. Place `tommy_boosting` in your resources folder.
2. Import `sql/tommy_boosting.sql` into MariaDB/MySQL.
3. Ensure order:
   - ensure oxmysql
   - ensure ox_lib
   - ensure tommy_boosting
4. Add items: boosting_laptop, tracker_remover, hacking_device, vin_scratcher, advanced_lockpick.
5. ACE example: `add_ace group.admin tommyboosting.admin allow`
6. Configure `Config.Framework` (`auto`,`qb`,`esx`,`standalone`).
7. Configure dispatch via `Config.Dispatch.system` and optional custom function.
8. Configure target via `Config.UseTarget` and `Config.TargetSystem`.
9. Troubleshooting: turn `Config.Debug=true` and check server console.
