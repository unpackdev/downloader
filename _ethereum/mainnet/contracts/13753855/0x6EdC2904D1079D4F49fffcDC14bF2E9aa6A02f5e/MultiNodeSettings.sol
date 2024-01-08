// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "./AdminAccess.sol";

contract MultiNodeSettings is AdminAccess {

  uint constant public NODE_TYPE_REWARD_BASE_RATE = 0;
  uint constant public NODE_TYPE_REWARD_DECAY_FACTOR = 1;
  uint constant public NODE_TYPE_FEE_STRONG = 2;
  uint constant public NODE_TYPE_FEE_CREATE = 3;
  uint constant public NODE_TYPE_FEE_RECURRING = 4;
  uint constant public NODE_TYPE_FEE_CLAIMING_NUMERATOR = 5;
  uint constant public NODE_TYPE_FEE_CLAIMING_DENOMINATOR = 6;
  uint constant public NODE_TYPE_RECURRING_CYCLE_SECONDS = 7;
  uint constant public NODE_TYPE_GRACE_PERIOD_SECONDS = 8;
  uint constant public NODE_TYPE_PAY_CYCLES_LIMIT = 9;
  uint constant public NODE_TYPE_NODES_LIMIT = 10;

  mapping(uint => bool) public nodeTypeActive;
  mapping(uint => bool) public nodeTypeHasSettings;
  mapping(uint => mapping(uint => uint)) public nodeTypeSettings;
  mapping(uint => mapping(string => uint)) public nodeTypeNFTBonus;

  // Events

  event SetNodeTypeActive(uint nodeType, bool active);
  event SetNodeTypeSetting(uint nodeType, uint settingId, uint value);
  event SetNodeTypeHasSettings(uint nodeType, bool hasSettings);
  event SetNodeTypeNFTBonus(uint nodeType, string bonusName, uint value);

  //
  // Getters
  // -------------------------------------------------------------------------------------------------------------------

  function getRewardBaseRate(uint _nodeType) public view returns (uint) {
    return getCustomSettingOrDefaultIfZero(_nodeType, NODE_TYPE_REWARD_BASE_RATE);
  }

  function getRewardDecayFactor(uint _nodeType) public view returns (uint) {
    return getCustomSettingOrDefaultIfZero(_nodeType, NODE_TYPE_REWARD_DECAY_FACTOR);
  }

  function getClaimingFeeNumerator(uint _nodeType) public view returns (uint) {
    return getCustomSettingOrDefaultIfZero(_nodeType, NODE_TYPE_FEE_CLAIMING_NUMERATOR);
  }

  function getClaimingFeeDenominator(uint _nodeType) public view returns (uint) {
    return getCustomSettingOrDefaultIfZero(_nodeType, NODE_TYPE_FEE_CLAIMING_DENOMINATOR);
  }

  function getCreatingFeeInWei(uint _nodeType) public view returns (uint) {
    return getCustomSettingOrDefaultIfZero(_nodeType, NODE_TYPE_FEE_CREATE);
  }

  function getRecurringFeeInWei(uint _nodeType) public view returns (uint) {
    return getCustomSettingOrDefaultIfZero(_nodeType, NODE_TYPE_FEE_RECURRING);
  }

  function getStrongFeeInWei(uint _nodeType) public view returns (uint) {
    return getCustomSettingOrDefaultIfZero(_nodeType, NODE_TYPE_FEE_STRONG);
  }

  function getRecurringPaymentCycle(uint _nodeType) public view returns (uint) {
    return getCustomSettingOrDefaultIfZero(_nodeType, NODE_TYPE_RECURRING_CYCLE_SECONDS);
  }

  function getGracePeriod(uint _nodeType) public view returns (uint) {
    return getCustomSettingOrDefaultIfZero(_nodeType, NODE_TYPE_GRACE_PERIOD_SECONDS);
  }

  function getPayCyclesLimit(uint _nodeType) public view returns (uint) {
    return getCustomSettingOrDefaultIfZero(_nodeType, NODE_TYPE_PAY_CYCLES_LIMIT);
  }

  function getNodesLimit(uint _nodeType) public view returns (uint) {
    return getCustomSettingOrDefaultIfZero(_nodeType, NODE_TYPE_NODES_LIMIT);
  }

  function getNftBonusValue(uint _nodeType, string memory _bonusName) public view returns (uint) {
    return nodeTypeNFTBonus[_nodeType][_bonusName] > 0
    ? nodeTypeNFTBonus[_nodeType][_bonusName]
    : nodeTypeNFTBonus[0][_bonusName];
  }

  //
  // Setters
  // -------------------------------------------------------------------------------------------------------------------

  function setNodeTypeActive(uint _nodeType, bool _active) external onlyRole(adminControl.SERVICE_ADMIN()) {
    // Node type 0 is being used as a placeholder for the default settings for node types that don't have custom ones,
    // So it shouldn't be activated and used to create nodes
    require(_nodeType > 0, "invalid type");
    nodeTypeActive[_nodeType] = _active;
    emit SetNodeTypeActive(_nodeType, _active);
  }

  function setNodeTypeHasSettings(uint _nodeType, bool _hasSettings) external onlyRole(adminControl.SERVICE_ADMIN()) {
    nodeTypeHasSettings[_nodeType] = _hasSettings;
    emit SetNodeTypeHasSettings(_nodeType, _hasSettings);
  }

  function setNodeTypeSetting(uint _nodeType, uint _settingId, uint _value) external onlyRole(adminControl.SERVICE_ADMIN()) {
    nodeTypeHasSettings[_nodeType] = true;
    nodeTypeSettings[_nodeType][_settingId] = _value;
    emit SetNodeTypeSetting(_nodeType, _settingId, _value);
  }

  function setNodeTypeNFTBonus(uint _nodeType, string memory _bonusName, uint _value) external onlyRole(adminControl.SERVICE_ADMIN()) {
    nodeTypeNFTBonus[_nodeType][_bonusName] = _value;
    emit SetNodeTypeNFTBonus(_nodeType, _bonusName, _value);
  }

  // -------------------------------------------------------------------------------------------------------------------

  function getCustomSettingOrDefaultIfZero(uint _nodeType, uint _setting) internal view returns (uint) {
    return nodeTypeHasSettings[_nodeType] && nodeTypeSettings[_nodeType][_setting] > 0
    ? nodeTypeSettings[_nodeType][_setting]
    : nodeTypeSettings[0][_setting];
  }

}
