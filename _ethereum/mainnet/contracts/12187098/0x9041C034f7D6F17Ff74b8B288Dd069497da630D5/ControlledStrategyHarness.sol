pragma solidity >=0.6.0 <0.7.0;

import "./ControlledStrategy.sol";
import "./ControlledStrategyDistributorInterface.sol";

/* solium-disable security/no-block-members */
contract ControlledStrategyHarness is ControlledStrategy {

  ControlledStrategyDistributorInterface distributor;

  function setDistributor(ControlledStrategyDistributorInterface _distributor) external {
    distributor = _distributor;
  }

  uint256 internal time;
  function setCurrentTime(uint256 _time) external {
    time = _time;
  }

  function _currentTime() internal override view returns (uint256) {
    return time;
  }

  function _distribute() internal override {
    distributor.distribute();
  }
}