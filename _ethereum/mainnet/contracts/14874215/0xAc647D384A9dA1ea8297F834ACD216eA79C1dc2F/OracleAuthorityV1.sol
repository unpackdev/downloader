// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.14;

//
//                                 (((((((((((()                                 
//                              (((((((((((((((((((                              
//                            ((((((           ((((((                            
//                           (((((               (((((                           
//                         (((((/                 ((((((                         
//                        (((((                     (((((                        
//                      ((((((                       ((((()                      
//                     (((((                           (((((                     
//                   ((((((                             (((((                    
//                  (((((                                                        
//                ((((((                        (((((((((((((((                  
//               (((((                       (((((((((((((((((((((               
//             ((((((                      ((((((             (((((.             
//            (((((                      ((((((.               ((((((            
//          ((((((                     ((((((((                  (((((           
//         (((((                      (((((((((                   ((((((         
//        (((((                     ((((((.(((((                    (((((        
//       (((((                     ((((((   (((((                    (((((       
//      (((((                    ((((((      ((((((                   (((((      
//      ((((.                  ((((((          (((((                  (((((      
//      (((((                .((((((            ((((((                (((((      
//       ((((()            (((((((                (((((             ((((((       
//        .(((((((      (((((((.                   ((((((((     ((((((((         
//           ((((((((((((((((                         ((((((((((((((((           
//                .((((.                                    (((()         
//                                  
//                               attrace.com
//

// import "./console.sol";
import "./Ownable.sol";
import "./SettingsV1.sol";
import "./SettingValidatorV1.sol";

// Oracle Authority 
//
// A single instance of this contract represent a genesis state for Attrace oracles to bootstrap from.
//
// Oracles start up with an OracleAuthorityV1 address and use it to resolve all their initialization state.
// After being operational, the oracles react to planned changes (and cancellations of planned changes if they are not yet in effect).
//
// This allows efficient internal design of the derived block code. All changes have to be announced, so all code can switch and prepare before processing blocks.
//
// This contract can live on a different chain than the pacemaker.
// All changes done to the oracles are event-like encoded on-chain and emitted. 
//
// The contract can encode start before it's deployment time, allowing oracles to plug into chains from historical points before it's deployment time.
// Any changes after deployment have to wait until oracles are synced upto change times.
//
// The DAO will become owner of this contract.
//
// The contract applies "irreversible" behavior: even the future DAO cannot revert historically activated changes for those time periods.
//
contract OracleAuthorityV1 is Ownable {
  
  // Pluggable setting validator
  SettingValidatorV1 public settingValidator;

  // Settings change history
  // releaseTime=0 indicates genesis setting
  Setting[] private changeHistory;

  // Static keys to set self address
  bytes32 constant AUTHORITY = "authority";
  bytes32 constant SETTING_VALIDATOR = "settingValidator";

  // Emitted whenever a setting change is planned
  event SettingConfigured(bytes32 indexed path0, bytes32 indexed pathIdx, bytes32[] path, uint64 releaseTime, bytes value);

  // Emitted whenever planned settings are cancelled
  event PendingSettingCancelled(bytes32 indexed path0, bytes32 indexed pathIdx, Setting setting);

  // When created, it's created with a genesis state
  constructor(Setting[] memory genesisSettings) {
    // Inject our own address to guarantee a unique genesis state related to this authority contract
    addSetting(Setting(settingToPath(AUTHORITY), 0, abi.encode(block.chainid, address(this))));

    // Add the requested genesis properties
    for(uint i = 0; i < genesisSettings.length; i++) {
      require(genesisSettings[i].releaseTime == 0, "400");
      addSetting(genesisSettings[i]);
    }

    // It's required to configure a setting validator during deployment
    require(address(settingValidator) != address(0), "400: settings");
  }

  // Return changeHistory size
  function changeCount() external view returns (uint256) {
    return changeHistory.length;
  }

  // Get a specific change from the change history
  function getChange(uint256 idx) external view returns (Setting memory) {
    return changeHistory[idx];
  }

  // Plan all future oracle changes. 
  // When planning new changes, you replace all previous planned changed.
  function planChanges(Setting[] calldata settings) external onlyOwner {
    // Remove any planned changes which have not been activated yet
    for(uint256 i = changeHistory.length-1; i >= 0; i--) {
      // Keep already active changes
      if(changeHistory[i].releaseTime <= block.timestamp) {
        break;
      }
      // Remove one entry from the end of the array
      emit PendingSettingCancelled(changeHistory[i].path[0], hashPath(changeHistory[i].path), changeHistory[i]);
      changeHistory.pop();
    }

    // Plan the new changes
    uint256 lastTime;
    for(uint i = 0; i < settings.length; i++) {
      require(
        // Validates it's a planned change
        settings[i].releaseTime > block.timestamp
        // Validates order
        && (lastTime > 0 ? settings[i].releaseTime >= lastTime : true)
        // Validates if it's allowed to change this setting
        && (settingValidator.isValidUnlockedSetting(settings[i].path, settings[i].releaseTime, settings[i].value) == true)
        , "400");

      // Plan setting + emit event
      addSetting(settings[i]);

      // Track last time
      lastTime = settings[i].releaseTime;
    }
  }

  function addSetting(Setting memory setting) private {
    // Activate setting validator changes, these apply instantly
    if(setting.path[0] == SETTING_VALIDATOR) {
      (address addr) = abi.decode(setting.value, (address));
      require(addr != address(0), "400");
      settingValidator = SettingValidatorV1(addr); // SettingValidator ignores the history concept
    }

    changeHistory.push(setting);
    emit SettingConfigured(setting.path[0], hashPath(setting.path), setting.path, setting.releaseTime, setting.value);
  }

  // -- don't accept raw ether
  receive() external payable {
    revert('unsupported');
  }

  // -- reject any other function
  fallback() external payable {
    revert('unsupported');
  }
}
