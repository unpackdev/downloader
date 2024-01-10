// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "./AddressUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

import "./FoundationTreasuryNode.sol";
import "./NFTMarketCore.sol";
import "./NFTMarketCreators.sol";

error SendValueWithFallbackWithdraw_No_Funds_Available();

/**
 * @title A mixin for sending ETH with a fallback withdraw mechanism.
 * @notice Attempt to send ETH and if the transfer fails or runs out of gas, store the balance
 * in the FETH token contract for future withdrawal instead.
 * @dev This mixin was recently switched to escrow funds in FETH.
 * Once we have confirmed all pending balances have been withdrawn, we can remove the escrow tracking here.
 */
abstract contract SendValueWithFallbackWithdraw is
  FoundationTreasuryNode,
  NFTMarketCore,
  ReentrancyGuardUpgradeable,
  NFTMarketCreators
{
  using AddressUpgradeable for address payable;

  /// @dev Tracks the amount of ETH that is stored in escrow for future withdrawal.
  mapping(address => uint256) private pendingWithdrawals;

  /**
   * @notice Emitted when escrowed funds are withdrawn to FETH.
   * @param user The account which has withdrawn ETH.
   * @param amount The amount of ETH which has been withdrawn.
   */
  event WithdrawalToFETH(address indexed user, uint256 amount);

  /**
   * @notice Allows a user to manually withdraw funds to FETH which originally failed to transfer to themselves.
   */
  function withdraw() external {
    withdrawFor(payable(msg.sender));
  }

  /**
   * @notice Allows anyone to manually trigger a withdrawal of funds
   * to FETH which originally failed to transfer for a user.
   * @param user The account which has escrowed ETH to withdraw.
   */
  function withdrawFor(address payable user) public nonReentrant {
    uint256 amount = pendingWithdrawals[user];
    if (amount == 0) {
      revert SendValueWithFallbackWithdraw_No_Funds_Available();
    }
    delete pendingWithdrawals[user];
    feth.depositFor{ value: amount }(user);
    emit WithdrawalToFETH(user, amount);
  }

  /**
   * @dev Attempt to send a user or contract ETH and
   * if it fails store the amount owned for later withdrawal in FETH.
   */
  function _sendValueWithFallbackWithdraw(
    address payable user,
    uint256 amount,
    uint256 gasLimit
  ) internal {
    if (amount == 0) {
      return;
    }
    // Cap the gas to prevent consuming all available gas to block a tx from completing successfully
    // solhint-disable-next-line avoid-low-level-calls
    (bool success, ) = user.call{ value: amount, gas: gasLimit }("");
    if (!success) {
      // Store the funds that failed to send for the user in the FETH token
      feth.depositFor{ value: amount }(user);
      emit WithdrawalToFETH(user, amount);
    }
  }

  /**
   * @notice Returns how much funds are available for manual withdraw due to failed transfers.
   * @param user The account to check the escrowed balance of.
   * @return balance The amount of funds which are available for withdrawal for the given user.
   */
  function getPendingWithdrawal(address user) external view returns (uint256 balance) {
    balance = pendingWithdrawals[user];
  }

  /**
   * @notice This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[499] private __gap;
}
