// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./IMasterChefV1.sol";
import "./AbstractStakeRedeemConnector.sol";

/**
 * Compatible with:
 * - MDEX: https://bscscan.com/address/0x6aee12e5eb987b3be1ba8e621be7c4804925ba68,
 *   pending rewards via pending(pid, user)
 */
contract MasterChefPowerIndexConnector is AbstractStakeRedeemConnector {
  uint256 public immutable MASTER_CHEF_PID;

  constructor(
    address _staking,
    address _underlying,
    address _piToken,
    uint256 _masterChefPid
  ) public AbstractStakeRedeemConnector(_staking, _underlying, _piToken, 46e12) {
    //6 hours with 13ms block
    MASTER_CHEF_PID = _masterChefPid;
  }

  /*** VIEWERS ***/

  function getPendingRewards() external view returns (uint256 amount) {
    return IMasterChefV1(STAKING).pending(MASTER_CHEF_PID, address(PI_TOKEN));
  }

  /*** OVERRIDES ***/

  function getUnderlyingStaked() external view override returns (uint256) {
    if (STAKING == address(0)) {
      return 0;
    }
    (uint256 amount, ) = IMasterChefV1(STAKING).userInfo(MASTER_CHEF_PID, address(PI_TOKEN));
    return amount;
  }

  function _claimImpl() internal override {
    _stakeImpl(0);
  }

  function _stakeImpl(uint256 _amount) internal override {
    _callExternal(PI_TOKEN, STAKING, IMasterChefV1.deposit.selector, abi.encode(MASTER_CHEF_PID, _amount));
  }

  function _redeemImpl(uint256 _amount) internal override {
    _callExternal(PI_TOKEN, STAKING, IMasterChefV1.withdraw.selector, abi.encode(MASTER_CHEF_PID, _amount));
  }
}
