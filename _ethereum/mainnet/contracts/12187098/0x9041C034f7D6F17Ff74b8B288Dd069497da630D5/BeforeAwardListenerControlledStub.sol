pragma solidity >=0.6.0 <0.7.0;

import "./BeforeAwardListenerControlled.sol";

/* solium-disable security/no-block-members */
contract BeforeAwardListenerControlledStub is BeforeAwardListenerControlled {

  event Awarded();

  function beforePrizePoolAwarded(uint256 prizePeriodStartedAt) external override {
    emit Awarded();
  }
}