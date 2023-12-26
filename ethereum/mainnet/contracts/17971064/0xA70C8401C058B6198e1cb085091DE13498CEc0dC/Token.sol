// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

import "./SafeERC20.sol";
import "./Address.sol";

/**
 * @title Token Library
 * @author Sam Bugs
 * @notice A small library that contains helpers for tokens (both ERC20 and native)
 */
library Token {
  using SafeERC20 for IERC20;
  using Address for address payable;
  using Address for address;

  /// @notice A specific target to distribute tokens to
  struct DistributionTarget {
    address recipient;
    uint256 shareBps;
  }

  address public constant NATIVE_TOKEN = address(0);

  /**
   * @notice Calculates the amount of token balance held by the contract
   * @param _token The token to check
   * @return _balance The current balance held by the contract
   */
  function balanceOnContract(address _token) internal view returns (uint256 _balance) {
    return _token == NATIVE_TOKEN ? address(this).balance : IERC20(_token).balanceOf(address(this));
  }

  /**
   * @notice Performs a max approval to the allowance target, for the given token
   * @param _token The token to approve
   * @param _allowanceTarget The spender that will be approved
   */
  function maxApprove(IERC20 _token, address _allowanceTarget) internal {
    setAllowance(_token, _allowanceTarget, type(uint256).max);
  }

  /**
   * @notice Performs an approval to the allowance target, for the given token and amount
   * @param _token The token to approve
   * @param _allowanceTarget The spender that will be approved
   * @param _amount The allowance to set
   */
  function setAllowance(IERC20 _token, address _allowanceTarget, uint256 _amount) internal {
    // This helper should handle cases like USDT. Thanks OZ!
    _token.forceApprove(_allowanceTarget, _amount);
  }

  /**
   * @notice Performs a max approval to the allowance target for the given token, as long as the token is not
   *         the native token, and the allowance target is not the zero address
   * @param _token The token to approve
   * @param _allowanceTarget The spender that will be approved
   */
  function maxApproveIfNecessary(address _token, address _allowanceTarget) internal {
    setAllowanceIfNecessary(_token, _allowanceTarget, type(uint256).max);
  }

  /**
   * @notice Performs an approval to the allowance target for the given token and amount, as long as the token is not
   *         the native token, and the allowance target is not the zero address
   * @param _token The token to approve
   * @param _allowanceTarget The spender that will be approved
   * @param _amount The allowance to set
   */
  function setAllowanceIfNecessary(address _token, address _allowanceTarget, uint256 _amount) internal {
    if (_token != NATIVE_TOKEN && _allowanceTarget != address(0)) {
      setAllowance(IERC20(_token), _allowanceTarget, _amount);
    }
  }

  /**
   * @notice Distributes the available amount of the given token according to the set distribution. All tokens
   *         will be distributed according to the configured shares. The last target will get sent all unassigned
   *         tokens
   * @param _token The token to distribute
   * @param _distribution How to distribute the available amount of the token. Must have at least one target
   */
  function distributeTo(
    address _token,
    DistributionTarget[] calldata _distribution
  )
    internal
    returns (uint256 _available)
  {
    _available = balanceOnContract(_token);
    uint256 _amountLeft = _available;

    // Distribute amounts
    for (uint256 i; i < _distribution.length - 1;) {
      uint256 _toSend = _available * _distribution[i].shareBps / 10_000;
      sendAmountTo(_token, _toSend, _distribution[i].recipient);
      _amountLeft -= _toSend;
      unchecked {
        ++i;
      }
    }

    // Send amount left to the last recipient
    sendAmountTo(_token, _amountLeft, _distribution[_distribution.length - 1].recipient);
  }

  /**
   * @notice Checks if the contract has any balance of the given token, and if it does,
   *         it sends it to the given recipient
   * @param _token The token to check
   * @param _recipient The recipient of the token balance
   * @return _balance The current balance held by the contract
   */
  function sendBalanceOnContractTo(address _token, address _recipient) internal returns (uint256 _balance) {
    _balance = balanceOnContract(_token);
    sendAmountTo(_token, _balance, _recipient);
  }

  /**
   * @notice Transfers the given amount of tokens from the contract to the recipient
   * @param _token The token to check
   * @param _amount The amount to send
   * @param _recipient The recipient
   */
  function sendAmountTo(address _token, uint256 _amount, address _recipient) internal {
    if (_amount > 0) {
      if (_recipient == address(0)) _recipient = msg.sender;
      if (_token == NATIVE_TOKEN) {
        payable(_recipient).sendValue(_amount);
      } else {
        IERC20(_token).safeTransfer(_recipient, _amount);
      }
    }
  }
}
