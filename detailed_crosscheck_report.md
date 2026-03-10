# Detailed API Cross-check Report: SkenaUI One Dark

This report documents the discrepancies between the One Dark themed scripts (`onedark/`) and the original SkenaUI implementation. These issues are the root cause of the "failed to load" errors.

## 1. Critical: File Format Corruption
Five critical files in the `onedark/` directory are currently stored as **JSON objects** instead of raw Lua. When the `SkenaUI.lua` loader attempts to `loadstring` these files, it results in a syntax error.

**Affected Files:**
- [SurvivetheCold.lua](file:///c:/Users/ken/Documents/GitHub/key/onedark/SurvivetheCold.lua)
- [SkillPointLegend.lua](file:///c:/Users/ken/Documents/GitHub/key/onedark/SkillPointLegend.lua)
- [darkdex.lua](file:///c:/Users/ken/Documents/GitHub/key/onedark/darkdex.lua)
- [CustomDex.lua](file:///c:/Users/ken/Documents/GitHub/key/onedark/CustomDex.lua)
- [CobaltSpy.lua](file:///c:/Users/ken/Documents/GitHub/key/onedark/CobaltSpy.lua)

> [!IMPORTANT]
> These files must be "unpacked" (base64 decoded) back into raw Lua for the loader to function.

## 2. API Mismatch: Missing Library Methods
The One Dark version of `SkenaUI_Library.lua` (27KB) is missing approximately 75% of the functionality present in the original (109KB).

### Missing UI Components
| Method | Used In | Status |
| :--- | :--- | :--- |
| `CreateAutoFarmGroup` | `SimpleSpells.lua` | ❌ Missing |
| `AddMultiSkillRow` | `SimpleSpells.lua` | ❌ Missing |
| `AddUnifiedActionRow` | `SimpleSpells.lua` | ❌ Missing |
| `CreateInputRow` | `Admin.lua`, `SimpleSpells.lua` | ❌ Missing |
| `CreateDoubleButtonRow` | `Admin.lua`, `Cold.lua` | ❌ Missing |
| `CreateToggleButtonRow` | `Admin.lua` | ❌ Missing |
| `CreateInputButtonRow` | `Admin.lua` | ❌ Missing |
| `CreateMultiSelectDropdown`| `Cold.lua` | ❌ Missing |

### Missing Utility Methods
| Method | Used In | Purpose |
| :--- | :--- | :--- |
| `UpdateCooldown` | Most game scripts | Updates HUD cooldown timers |
| `SetToggleKey` | Settings tab | Rebinds the UI toggle key |

## 3. Implementation Recommendations
To resolve these issues without breaking the "One Dark" aesthetic:

1.  **Porting Logic**: Copy the logic for the missing methods from the original [SkenaUI_Library.lua](file:///c:/Users/ken/Documents/GitHub/key/SkenaUI_Library.lua) into the One Dark version.
2.  **Theme Integration**: When porting, replace original `Palette` references (Windows 11 colors) with the One Dark `P` table colors.
3.  **File Repair**: Decode the JSON-wrapped files back to raw Lua.

> [!TIP]
> I have identified the exact line numbers and logic in the original library for every missing component. I am ready to proceed with a "Dry Run" implementation if requested.
