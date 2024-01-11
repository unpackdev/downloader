// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.14;

// import "./console.sol";
import "./Ownable.sol";
import "./SettingsV1.sol";
import "./SettingValidatorV1.sol";

struct SettingRule {
  bool isFrozen;
  uint64 lockedUntil;
}

// Extends an ownable contract with functionality which allows configuring and freezing settings.
abstract contract SettingRulesConfigurable is Ownable, SettingValidatorV1 {

  // Change rules on a certain setting to support secure go-live of the network.
  // The key here is the keccak256(abi.encode(...setting.path)), iterated by the path levels, which allows locking granular settings or specific subsettings
  mapping(bytes32 => SettingRule) internal rules;

  event PathRuleSet(bytes32 indexed path0, bytes32 indexed pathIdx, bytes32[] path, SettingRule rule);

  // ExternalData interface used by authority
  function isValidUnlockedSetting(bytes32[] calldata path, uint64, bytes calldata) external view override isPathUnlocked_(path) returns (bool) {
    return true;
  }

  // -- GETTERS

  function getRule(bytes32[] calldata path) external view returns (SettingRule memory) {
    return rules[hashPath(path)];
  }

  // TODO future versions should check paths breadth-first. Since we don't need this yet and only require the structure, this is not yet implemented.
  function isPathUnlocked(bytes32[] calldata path) public view returns (bool) {
    bytes32 pathHash = hashPath(path);
    return rules[pathHash].isFrozen == false && rules[pathHash].lockedUntil < block.timestamp;
  }
  // -- SETTERS

  // Set irriversible rules on the abi-encoded values
  function setPathRule(bytes32[] calldata path, SettingRule calldata rule) external onlyOwner isPathUnlocked_(path) {
    require(path.length > 0, "400");
    bytes32 pathHash = hashPath(path);
    rules[pathHash] = rule;
    emit PathRuleSet(path[0], pathHash, path, rule);
  }

  // -- MODIFIERS

  // Check if a value (or it's rules) are unlocked for changes.
  modifier isPathUnlocked_(bytes32[] calldata path) {
    require(isPathUnlocked(path), "403");
    _;
  }
}

// More ideas here are to extend this with some setting-filter which (can) restrict updates to the values, eg: frozen-forever, frozen-TIMEdelay, supermajority, delayed-doubleconfirmation, ... we should watch out for complexity and impact to security models when looking into this.