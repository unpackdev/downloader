// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./IPancakeMasterChef.sol";
import "./AbstractStakeRedeemConnector.sol";

/**
 * Compatible with:
 * - Pancake: https://bscscan.com/address/0x73feaa1ee314f8c655e354234017be2193c9e24e
 * To get pending rewards use IPancakeStaking(0x73feaa1ee314f8c655e354234017be2193c9e24e).pendingCake(0, piToken).
 */
contract PancakeMasterChefIndexConnector is AbstractStakeRedeemConnector {
  uint256 internal constant PANCAKE_POOL_ID = 0;

  constructor(
    address _staking,
    address _underlying,
    address _piToken
  ) public AbstractStakeRedeemConnector(_staking, _underlying, _piToken, 46e12) {} //6 hours with 13ms block

  /*** VIEWERS ***/

  function getPendingRewards() external view returns (uint256 amount) {
    return IPancakeMasterChef(STAKING).pendingCake(PANCAKE_POOL_ID, address(PI_TOKEN));
  }

  /*** OVERRIDES ***/

  function getUnderlyingStaked() external view override returns (uint256) {
    if (STAKING == address(0)) {
      return 0;
    }
    (uint256 amount, ) = IPancakeMasterChef(STAKING).userInfo(PANCAKE_POOL_ID, address(PI_TOKEN));
    return amount;
  }

  function _claimImpl() internal override {
    _stakeImpl(0);
  }

  function _stakeImpl(uint256 _amount) internal override {
    _callExternal(PI_TOKEN, STAKING, IPancakeMasterChef.enterStaking.selector, abi.encode(_amount));
  }

  function _redeemImpl(uint256 _amount) internal override {
    _callExternal(PI_TOKEN, STAKING, IPancakeMasterChef.leaveStaking.selector, abi.encode(_amount));
  }
}
