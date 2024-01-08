pragma solidity ^0.8.5;

import "./ITrigger.sol";

contract MockTrigger is ITrigger {
  /// @notice If true, checkAndToggleTrigger will toggle the trigger on its next call
  bool public shouldToggle;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _description,
    uint256[] memory _platformIds,
    address _recipient,
    bool _shouldToggle
  ) ITrigger(_name, _symbol, _description, _platformIds, _recipient) {
    shouldToggle = _shouldToggle;

    // Verify market is not already triggered.
    require(!checkTriggerCondition(), "Already triggered");
  }

  /**
   * @notice Special function for this mock trigger to set whether or not the trigger should toggle
   */
  function setShouldToggle(bool _shouldToggle) external {
    require(!isTriggered, "Cannot set after trigger event");
    shouldToggle = _shouldToggle;
  }

  /**
   * @notice Returns true if the market has been triggered, false otherwise
   */
  function checkTriggerCondition() internal view override returns (bool) {
    return shouldToggle;
  }
}
