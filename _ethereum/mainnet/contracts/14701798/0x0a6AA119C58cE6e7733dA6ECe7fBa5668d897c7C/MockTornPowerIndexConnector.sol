pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./TornPowerIndexConnector.sol";

contract MockTornPowerIndexConnector is TornPowerIndexConnector {
  constructor(
    address _staking,
    address _underlying,
    address _piToken,
    address _governance
  ) public TornPowerIndexConnector(_staking, _underlying, _piToken, _governance) {}

  function getTornPriceRatio() public view override returns (uint256) {
    return 15000000000000000;
  }
}
