// SPDX-License-Identifier: Apache-2.0-with-puul-exception
pragma solidity >=0.6.12;
import "./StakingBase.sol";

contract PuulStakingPool is StakingBase {
  constructor (address token, address fees, address helper) public StakingBase('PUUL Staking Token', 'PUULSTK', token, fees, helper) {
  }

  // The PuulStakingPool doesn't use the attached farm to earn anything. It just collects the rewards
  // and withdrawal fees from the farm.
  function _earn() override internal {  }
  function _unearn(uint256 amount) internal override { }

}
