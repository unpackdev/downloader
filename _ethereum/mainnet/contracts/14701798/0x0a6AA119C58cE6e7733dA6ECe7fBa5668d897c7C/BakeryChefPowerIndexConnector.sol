// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./IBakeryMasterChef.sol";
import "./AbstractStakeRedeemConnector.sol";

/**
 * Compatible with:
 * - Bakery: https://bscscan.com/address/0x20ec291bb8459b6145317e7126532ce7ece5056f,
 *   pending rewards via pendingBake(pair, user)
 * @dev Notice that in deposit/withdraw/pending Bake method signatures, Bakery uses the staking token addresses
 *      instead of numerical pool IDs like in most masterChef forks.
 */
contract BakeryChefPowerIndexConnector is AbstractStakeRedeemConnector {
  constructor(
    address _staking,
    address _underlying,
    address _piToken
  ) public AbstractStakeRedeemConnector(_staking, _underlying, _piToken, 46e12) {} //6 hours with 13ms block

  /*** VIEWERS ***/

  function getPendingRewards() external view returns (uint256 amount) {
    return IBakeryMasterChef(STAKING).pendingBake(address(UNDERLYING), address(PI_TOKEN));
  }

  /*** OVERRIDES ***/

  function getUnderlyingStaked() external view override returns (uint256) {
    if (STAKING == address(0)) {
      return 0;
    }
    (uint256 amount, ) = IBakeryMasterChef(STAKING).poolUserInfoMap(address(UNDERLYING), address(PI_TOKEN));
    return amount;
  }

  function _claimImpl() internal override {
    _stakeImpl(0);
  }

  function _stakeImpl(uint256 _amount) internal override {
    _callExternal(PI_TOKEN, STAKING, IBakeryMasterChef.deposit.selector, abi.encode(address(UNDERLYING), _amount));
  }

  function _redeemImpl(uint256 _amount) internal override {
    _callExternal(PI_TOKEN, STAKING, IBakeryMasterChef.withdraw.selector, abi.encode(address(UNDERLYING), _amount));
  }
}
