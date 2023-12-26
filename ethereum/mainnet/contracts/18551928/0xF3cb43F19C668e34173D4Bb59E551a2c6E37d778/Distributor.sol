// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./Address.sol";
import "./IWETH.sol";
import "./Utils.sol";

abstract contract Distributor is Utils {
  using Address for address payable;

  event FeesDistributed(uint256 amount);

  /**
   * distributes all fees, after withdrawing wrapped native balance
   * @notice if the amount is 0, all funds will be drained
   * @notice if an amount is provided, the method will only unwrap
   * the wNative token if it does not have enough native balance to cover the amount
   * @notice the balance will change in the middle of the function
   * if the appropriate conditions are met. however, we do not use that updated balance
   * because the whole amount may not have been asked for
   */
  function distributeAll(uint256 amount) external payable {
    (uint256 nativeBalance, uint256 wNativeBalance) = pendingDistributionSegmented();
    _unwrapValue(amount, nativeBalance, wNativeBalance);
    _sendValue(amount, (nativeBalance + wNativeBalance));
  }

  /**
   * A public method to distribute fees
   * @param amount the amount of ether to distribute
   * @notice failure in receipt will cause this tx to fail as well
   */
  function distribute(uint256 amount) external payable {
    uint256 balance = address(this).balance;
    if (balance < 0) {
      return;
    }
    _sendValue(amount, balance);
  }
  function _unwrapValue(
    uint256 amount,
    uint256 _nativeBalance,
    uint256 _wNativeBalance
  ) internal {
    if ((amount == 0 || _nativeBalance < amount) && _wNativeBalance > 0) {
      IWETH(wNative).withdraw(_wNativeBalance);
    }
  }
  function _sendValue(uint256 amount, uint256 limit) internal {
    amount = _clamp(amount, limit);
    if (amount == 0) {
      return;
    }
    destination.sendValue(amount);
    emit FeesDistributed(amount);
  }

  /**
   * returns the balance in wNative token and native token as two separate numbers
   */
  function pendingDistributionSegmented() public view returns(uint256, uint256) {
    return (address(this).balance, IWETH(wNative).balanceOf(address(this)));
  }

  /**
   * returns the balance of wNative token and native token,
   * treating them as an aggregate balance for ease
   */
  function pendingDistribution() public view returns(uint256) {
    (uint256 nativeBalance, uint256 wNativeBalance) = pendingDistributionSegmented();
    return nativeBalance + wNativeBalance;
  }
}