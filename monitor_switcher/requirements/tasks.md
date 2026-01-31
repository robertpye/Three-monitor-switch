# Implementation Plan: Windows Display Switcher

## Overview

This implementation plan breaks down the Windows Display Switcher into discrete coding tasks. The approach focuses on building core functionality first, then adding validation, error handling, and advanced features. Each task builds incrementally to ensure the system remains functional throughout development.

## Current Status

**Phase 1 Complete**: Core DisplayFusion integration is working. The script can successfully switch between monitor profiles using DisplayFusion's command-line interface.

**Key Achievement**: Discovered and documented the registry setting to disable DisplayFusion's confirmation dialog, enabling fully automated/remote monitor switching.

## Completed Tasks

- [x] 1. Set up project structure and core script framework
  - Created DisplaySwitcher.bat main entry point
  - Implemented command-line argument parsing (profile selection, verbose mode, help)
  - Set up configuration variables for 3-monitor setup
  - Created logging infrastructure with timestamp support
  - _Requirements: 6.1, 8.2_

- [x] 2. Implement DisplayFusion interface layer
  - [x] 2.1 Create DisplayFusion command execution functions
    - Implemented ApplyDisplayFusionProfile function using `-monitorloadprofile`
    - Implemented EnableMonitor and DisableMonitor functions (via DisplayFusion functions)
    - Implemented QueryDisplayFusionState function using Windows WMI
    - Added error code handling for DisplayFusion commands
    - _Requirements: 9.1_

  - [x] 2.3 Implement timing and stabilization functions
    - Created WaitForStabilization function with configurable delays
    - Implemented adaptive delay calculation based on operation type
    - Added monitor state detection via WMI
    - _Requirements: 7.1, 7.2, 7.5_

- [x] 3. Checkpoint - Basic DisplayFusion integration verified
  - DisplayFusion profile loading works via CLI
  - Monitor state detection works via Windows WMI
  - Timing/stabilization delays functioning
  - Verbose logging working correctly
  - **Bonus**: Discovered registry key to disable confirmation dialog

- [x] 12.5 Add help/usage display
  - Implemented display of available configuration options when invoked without parameters
  - _Requirements: 8.4_

- [x] 13. Create configuration profile definitions (Partial - User Created)
  - User created DisplayFusion monitor profiles:
    - TripleMonitor (all three monitors)
    - SingleCenter (center only)
  - Remaining profiles to be created as needed:
    - DualWork (center + right)
    - DualVertical (center + left)
  - _Requirements: 8.2_

## Additional Completed Work (Not in Original Plan)

- [x] Registry configuration for automated switching
  - Discovered `MonitorConfigDontShowConfirmPrompt` registry key
  - Created DisableDisplayFusionConfirmPrompt.reg
  - Created EnableDisplayFusionConfirmPrompt.reg
  - Documented in README.md

- [x] Project reorganization
  - Moved files to monitor_switcher/ folder
  - Deleted legacy MultiMonitorTool files
  - Updated README.md with new structure

## Remaining Tasks

- [ ]* 1.1 Write property test for command-line argument parsing
  - **Property 21: Command-Line Interface**
  - **Validates: Requirements 8.2**

- [ ]* 2.2 Write property test for DisplayFusion operations
  - **Property 22: Monitor Enable/Disable Operations**
  - **Validates: Requirements 9.1, 9.4**

- [ ]* 2.4 Write property test for timing management
  - **Property 10: Adaptive Timing Management**
  - **Validates: Requirements 7.1, 7.2, 7.5**

- [ ] 4. Implement configuration management system
  - [ ] 4.1 Create configuration profile definitions
  - [ ] 4.3 Implement current state detection
  - [ ] 4.6 Implement no-op optimization

- [ ] 5. Implement validation engine
  - [ ] 5.1 Create core validation functions
  - [ ] 5.4 Implement multi-system consistency checking

- [ ] 7. Implement error handling and recovery system
  - [ ] 7.1 Create retry mechanism with progressive delays
  - [ ] 7.3 Implement fallback mechanisms
  - [ ] 7.5 Implement backup restoration
  - [ ] 7.7 Implement partial failure handling
  - [ ] 7.9 Create comprehensive error handling dispatcher

- [ ] 8. Implement comprehensive logging system enhancements
  - [ ] 8.1 Enhance logging functions (rolling log, before/after states)

- [ ] 9. Implement monitor-specific configuration logic
  - [ ] 9.1 Create 3-monitor setup functions
  - [ ] 9.5 Implement enable/disable state management

- [ ] 10. Implement operation sequencing and coordination
  - [ ] 10.1 Create operation sequencer

- [ ] 12. Implement main controller and integration
  - [ ] 12.1 Wire all components together in main controller
  - [ ] 12.3 Implement configuration caching

- [ ] 14. Final integration testing and validation

- [ ] 15. Final checkpoint - Comprehensive system validation

## Notes

- Tasks marked with `*` are optional property tests that can be skipped for faster MVP
- The core functionality (profile switching) is now working
- DisplayFusion profiles must be created manually through DisplayFusion UI
- Registry key `MonitorConfigDontShowConfirmPrompt` must be set for automated switching
- Project files are now in `monitor_switcher/` folder
