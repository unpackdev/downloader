pragma solidity ^0.8.5;

import "./ITrigger.sol";

/**
 * @notice Mock MockCozyToken, for testing the return value of a trigger's `checkAndToggleTrigger()` method
 */
contract MockCozyToken {
  /// @notice Trigger contract address
  address public immutable trigger;

  /// @notice In a real Cozy Token, this state variable is toggled when trigger event occues
  bool public isTriggered;

  constructor(address _trigger) {
    // Set the trigger address in the constructor
    trigger = _trigger;
  }

  /**
   * @notice Sufficiently mimics the implementation of a Cozy Token's `checkAndToggleTriggerInternal()` method
   */
  function checkAndToggleTrigger() external {
    isTriggered = ITrigger(trigger).checkAndToggleTrigger();
  }
}
