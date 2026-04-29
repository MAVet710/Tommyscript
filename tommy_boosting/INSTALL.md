# Tommy Boosting Install
1. Import `sql/tommy_boosting.sql`.
2. Add to `server.cfg`:
   ensure oxmysql
   ensure ox_lib
   ensure tommy_boosting
3. Add items: boosting_laptop, tracker_remover, hacking_device, vin_scratcher, advanced_lockpick.
4. ACE: `add_ace group.admin tommyboosting.admin allow`.
5. Configure `Config.Framework`, `Config.Inventory`, `Config.UseTarget`, `Config.TargetSystem`, and `Config.Dispatch` in `config.lua`.
6. Open UI with `/boosting` or usable `boosting_laptop`.
7. Test: accept contract -> find car -> hack/remove tracker (if required) -> deliver to dropoff.
8. Troubleshooting: enable `Config.Debug=true`, confirm oxmysql/ox_lib started, check SQL imported.
