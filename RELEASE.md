# Release Notes - Lite Branch

This document describes all changes made to the **lite** branch since the last release.

---

## Version 7.13b (Latest)

### Date: June 3, 2026

### Summary of Changes
- Fixed printer backslash issue in setup scripts
- Updated Debian repository mirrors to Yandex mirrors
- Refactored printer driver paths for better organization

---

## Version History

### Version 7.13b - "Change driver path"
**Commit:** `7675806` (Mon, Apr 20, 2026)
- Updated driver file paths in `app/printer/setup.sh`

### Version 7.13a - "Change driver path"
**Commit:** `93bf9af` (Mon, Apr 20, 2026)
- Updated driver file paths in `app/printer/setup.sh`

### Version 7.13 - "Change driver path"
**Commit:** `b981b38` (Mon, Apr 20, 2026)
- Updated driver file paths in `app/printer/setup.sh`

### Version 7.13 (Earlier) - "Change driver path"
**Commit:** `993644e` (Mon, Apr 20, 2026)
- Updated driver file paths in `app/printer/setup.sh`

### Version 7.12 - "Change driver names"
**Commit:** `594c028` (Mon, Apr 20, 2026)
- Renamed driver files across all printer driver directories:
  - `Atol_RP326/driver.ppd`
  - `Custom_VKP80III_3/driver.ppd`
  - `Custom_VKP80II_2/driver.ppd`
  - `POScenter_RP-100_VCOM/driver.ppd`
  - `Sam4s_102c/driver.ppd`
  - `Universal/driver.ppd`
- Updated setup.sh scripts accordingly

### Version 7.11 - "Change if states"
**Commit:** `77b43ee` (Mon, Apr 20, 2026) & `861d730` (Mon, Apr 20, 2026)
- Modified conditional logic in `app/printer/setup.sh`

### Version 7.10 - "Change filters name in .ppd"
**Commit:** `b18cae7` (Mon, Apr 20, 2026)
- Renamed filter files in all driver directories:
  - `Printer80.ppd` → `driver.ppd`
  - `VKP80.ppd` → `driver.ppd`
  - `KPOS_80c.ppd` → `driver.ppd`
  - `SAM4s_gcube-102.ppd` → `driver.ppd`
- Updated setup.sh to reference new paths

### Version 7.9-7 - "VNC - remove comments"
**Commit:** `ddcfff0` (Fri, Mar 27, 2026)
- Cleaned up VNC setup scripts by removing comments
- Files modified:
  - `app/vnc/disable.sh`
  - `app/vnc/enable.sh`
  - `app/vnc/setup.sh`

---

## Detailed Change Summary

### Files Modified in Latest Release

| File | Changes |
|------|---------|
| `app/printer/setup.sh` | 17 lines changed - Fixed backslash issues, updated driver paths, removed trailing backslashes, refactored settings.ini configuration |
| `app/sst/setup.sh` | 19 lines changed - Updated Debian repository mirrors, cleaned up comments, fixed path references |

### Specific Improvements

1. **Driver Path Organization**
   - Consolidated all driver files under `app/printer/driver/`
   - Standardized naming convention: `driver.ppd` for all printer drivers
   - Simplified path references in setup scripts

2. **Repository Updates**
   - Changed Debian mirrors to Yandex mirrors for better availability
   - Updated from `deb.debian.org` to `mirror.yandex.ru/debian`
   - Upgraded to Debian trixie sources

3. **Script Cleanup**
   - Removed unnecessary comments from VNC scripts
   - Fixed conditional logic in printer setup
   - Corrected file path references (removed trailing backslashes)

4. **Settings Configuration**
   - Fixed quote escaping in settings.ini updates
   - Simplified `crudini` commands
   - Removed redundant configuration lines

### Print Filter Path Fix

The following change was made to fix the raster filter path:

```bash
# Before:
sudo cp app/printer/"$printer"/raster_to_printer /usr/lib/cups/filter/

# After:
sudo cp app/printer/driver/"$printer"/raster_to_printer /usr/lib/cups/filter/
```

### LP Admin Configuration Update

Printer registration command updated:

```bash
# Before:
sudo lpadmin -p SAM4S -E -v $PRINTER_URI -P /tmp/get_kiosk-main/app/printer/driver/$printer/driver.ppd

# After:
sudo lpadmin -p $printer -E -v $PRINTER_URI -P /tmp/get_kiosk-lite/app/printer/driver/$printer/*.ppd
```

---

## Git Branch Information

- **Current Branch:** `lite` (origin/lite)
- **Latest Commit:** `88a9f0f49f4dc64f77975561114ff7cec547ddcc`
- **Total Commits:** 20+ commits from #6.0 to 7.13b
- **Main Branch:** `main` (origin/main, origin/HEAD)

---

## Migration Notes

### For Users Upgrading to 7.13+

1. **Printer Driver Files:** Ensure your custom printer drivers are in the new `app/printer/driver/` directory structure
2. **Filter Path:** Verify that the new driver path is used for filter installation
3. **Settings.ini:** Existing settings may need to be regenerated due to configuration changes
4. **Repository Sources:** After upgrade, run `apt-get update` to fetch packages from new Yandex mirrors

### Backward Compatibility

- Versions 7.0+ remain compatible with older configurations
- Custom printer models may need driver file path updates
- VNC scripts have been cleaned but functionality remains unchanged

---

## Contributors

- **l0st0npl4net** (barrberry66@yandex.ru) - Primary developer on lite branch

---

## Technical Notes

### Debian Mirror Change Rationale
The switch from official Debian mirrors to Yandex mirrors was made to:
- Improve download speeds in Russian regions
- Ensure better package availability during network disruptions
- Reduce dependency on external infrastructure

### Driver Naming Convention
All printer drivers now follow the pattern:
```
app/printer/driver/{printer_name}/driver.ppd
```

This standardization simplifies:
- Bulk driver updates
- Custom printer additions
- Troubleshooting and debugging

---

## Future Improvements

- [ ] Consider adding checksums for driver verification
- [ ] Add more descriptive comments to VNC scripts
- [ ] Document all custom printer model configurations
- [ ] Create automated testing for printer setup scripts

---

## Support

For issues related to this release:
1. Check existing printer driver configurations
2. Verify Debian mirror accessibility
3. Review updated setup scripts for path references

---

*Generated on: $(date)*
*Branch: lite*
