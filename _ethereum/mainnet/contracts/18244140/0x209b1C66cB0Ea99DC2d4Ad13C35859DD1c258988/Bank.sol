// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "./Address.sol";
import { IERC20 } from  "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./SafeERC20.sol";
import "./Utils.sol";

/**
 * @title A subcontract to track balances of deposited tokens
 */
contract Bank is Utils {
  using Address for address payable;
  using SafeERC20 for IERC20;

  /**
   * notes that a previously unattributed token has been
   * collected and attributed to an address
   * @param token the token that is being collected by the caller
   * @param to the address that the tokens are being attributed to
   * @param amount the number of tokens being collected for the to address
   */
  event CollectUnattributedToken(address indexed token, address indexed to, uint256 amount);
  /**
   * @notice keeps a global mapping of attributed funds that the contract is custodying
   */
  mapping(address token => uint256 balance) public attributed;
  /**
   * @notice keeps a mapping of the withdrawable funds that the contract is custodying
   * the contract may also be custodying tips, but an amount held within
   * a tip is not withdrawable so it cannot be held in this mapping
   */
  mapping(address token => mapping(address account => uint256 balance)) public withdrawableBalanceOf;
  /**
   * gets unattributed tokens floating in the contract
   * @param token the address of the token that you wish to get the unattributed value of
   * @return amount representing the amount of tokens that have been
   * deposited into the contract, which are not attributed to any address
   */
  function _getUnattributed(address token) internal view returns(uint256 amount) {
    return _getBalance({
      token: token,
      owner: address(this)
    }) - attributed[token];
  }
  /**
   * get the balance and ownership of any token
   * @param token the token address that you wish to get the balance of (including native)
   * @param owner the owner address to get the balance of
   * @return amount of a balance custodied by this contract
   */
  function _getBalance(address token, address owner) internal view returns(uint256 amount) {
    return token == address(0) ? owner.balance : IERC20(token).balanceOf(owner);
  }
  /**
   * gets the amount of unattributed tokens
   * @param token the token to get the unattributed balance of
   * @return amount of a token that can be withdrawn
   */
  function getUnattributed(address token) external view returns(uint256 amount) {
    return _getUnattributed({
      token: token
    });
  }
  /**
   * given a provided input amount, clamp the input to a maximum, using maximum if 0 provided
   * @param amount the requested or input amount
   * @param max the maximum amount that the value can be
   * @return clamped the clamped value that is set to the limit if
   * 0 or a number above the limit is passed
   */
  function clamp(uint256 amount, uint256 max) external pure returns(uint256 clamped) {
    return _clamp({
      amount: amount,
      max: max
    });
  }
  /**
   * clamp a given amount to the maximum amount
   * use the maximum amount if no amount is requested
   * @param amount the amount requested by another function
   * @param max the limit that the value can be
   * @return clamped the clamped value that is set to the limit if
   * 0 or a number above the limit is passed
   */
  function _clamp(uint256 amount, uint256 max) internal pure returns(uint256 clamped) {
    unchecked {
      return amount == ZERO || amount > max ? max : amount;
    }
  }
  /**
   * transfer a given number of tokens to the contract to be used by the contract's methods
   * @param amount the number of tokens to transfer to the contract
   * @notice an extra layer of protection is provided by this method
   * and can be refused by calling the dangerous version
   */
  function depositToken(address token, uint256 amount) external payable returns(uint256) {
    return _depositTokenTo({
      token: token,
      to: msg.sender,
      amount: amount
    });
  }
  /**
   * deposit an amount of tokens to the contract and attribute
   * them to the provided address
   * @param to the account to give ownership over tokens
   * @param amount the amount of tokens
   */
  function depositTokenTo(address token, address to, uint256 amount) external payable returns(uint256) {
    return _depositTokenTo({
      token: token,
      to: to,
      amount: amount
    });
  }
  function _depositTokenTo(address token, address to, uint256 amount) internal returns(uint256) {
    amount = _depositTokenFrom({
      token: token,
      depositor: msg.sender,
      amount: amount
    });
    _addToTokenWithdrawable({
      token: token,
      to: to,
      amount: amount
    });
    return amount;
  }
  /**
   * collect unattributed tokens and send to recipient of choice
   * @param transferOut transfers tokens to the provided address
   * @param to the address to receive or have tokens attributed to
   * @param amount the requested amount - clamped to the amount unattributed
   * @notice when 0 is passed, withdraw maximum available
   * or in other words, all unattributed tokens
   */
  function collectUnattributed(
    address token, bool transferOut,
    address payable to,
    uint256 amount
  ) external payable returns(uint256) {
    return _collectUnattributed({
      token: token,
      transferOut: transferOut,
      to: to,
      amount: amount,
      max: _getUnattributed(token)
    });
  }
  function _collectUnattributed(
    address token, bool transferOut, address payable to,
    uint256 amount, uint256 max
  ) internal returns(uint256 withdrawable) {
    withdrawable = _clamp(amount, max);
    if (withdrawable > ZERO) {
      if (transferOut) {
        _withdrawTokenTo({
          token: token,
          to: to,
          amount: withdrawable
        });
      } else {
        _addToTokenWithdrawable({
          token: token,
          to: to,
          amount: withdrawable
        });
      }
      emit CollectUnattributedToken({
        token: token,
        to: to,
        amount: amount
      });
    }
  }
  /**
   * collect a number of unattributed tokens as basis points
   * @param token the token that you wish to collect
   * @param transferOut whether to transfer token out
   * @param recipient the recipient of the tokens
   * @param basisPoints the number of basis points (100% = 10_000)
   * @notice collecting unattributed percentages should
   * be used before a blanket collection
   * in order to reduce rounding errors
   * @dev please be sure to run blanket collect unattributed
   * calls to collect any remaining tokens
   */
  function collectUnattributedPercent(
    address token, bool transferOut, address payable recipient,
    uint256 basisPoints
  ) external returns(uint256 amount) {
    uint256 unattributed = _getUnattributed(token);
    amount = (unattributed * basisPoints) / TEN_K;
    _collectUnattributed(token, transferOut, recipient, amount, unattributed);
  }
  /**
   * transfer an amount of tokens currently attributed to the withdrawable balance of the sender
   * @param token the token to transfer - uses address(0) for native
   * @param to the to of the funds
   * @param amount the amount that should be deducted from the sender's balance
   */
  function withdrawTokenTo(address token, address payable to, uint256 amount) external payable returns(uint256) {
    return _withdrawTokenTo({
      token: token,
      to: to,
      amount: _deductWithdrawable({
        token: token,
        account: msg.sender,
        amount: amount
      })
    });
  }
  function _getTokenBalance(address token) internal view returns(uint256) {
    return token == address(0)
      ? address(this).balance
      : IERC20(token).balanceOf(address(this));
  }

  /**
   * adds a balance to the provided staker of the magnitude given in amount
   * @param token the token being accounted for
   * @param to the account to add a withdrawable balance to
   * @param amount the amount to add to the staker's withdrawable balance as well as the attributed tokens
   */
  function _addToTokenWithdrawable(address token, address to, uint256 amount) internal {
    unchecked {
      withdrawableBalanceOf[token][to] = withdrawableBalanceOf[token][to] + amount;
      attributed[token] = attributed[token] + amount;
    }
  }
  /**
   * deduce an amount from the provided account
   * @param account the account to deduct funds from
   * @param amount the amount of funds to deduct
   * @notice after a deduction, funds could be considered "unattributed"
   * and if they are left in such a state they could be picked up by anyone else
   */
  function _deductWithdrawable(address token, address account, uint256 amount) internal returns(uint256) {
    uint256 withdrawable = withdrawableBalanceOf[token][account];
    amount = _clamp({
      amount: amount,
      max: withdrawable
    });
    unchecked {
      withdrawableBalanceOf[token][account] = withdrawable - amount;
      attributed[token] = attributed[token] - amount;
    }
    return amount;
  }
  /** deposits tokens from a staker and marks them for that staker */
  function _depositTokenFrom(address token, address depositor, uint256 amount) internal returns(uint256 amnt) {
    if (token != address(0)) {
      if (amount > ZERO) {
        amnt = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransferFrom(depositor, address(this), amount);
        amnt = IERC20(token).balanceOf(address(this)) - amnt;
      }
    } else {
      // transfer in already occurred
      // make sure that multicall is not payable (it isn't)
      amnt = msg.value;
    }
  }
  /**
   * deposit a number of tokens to the contract
   * @param amount the number of tokens to deposit
   */
  function depositTokenUnattributed(address token, uint256 amount) external {
    _depositTokenFrom({
      token: token,
      depositor: msg.sender,
      amount: amount
    });
  }
  /**
   * transfers tokens to a recipient
   * @param to where to send the tokens
   * @param amount the number of tokens to send
   */
  function _withdrawTokenTo(address token, address payable to, uint256 amount) internal returns(uint256) {
    if (token == address(0)) {
      to.sendValue(amount);
    } else {
      IERC20(token).safeTransfer(to, amount);
    }
    return amount;
  }
  function _attributeFunds(uint256 settings, address token, address staker, uint256 amount) internal {
    if (_isOneAtIndex({
      settings: settings,
      index: FOUR
    })) {
      _withdrawTokenTo({
        token: token,
        to: payable(staker),
        amount: amount
      });
    } else {
      _addToTokenWithdrawable({
        token: token,
        to: staker,
        amount: amount
      });
    }
  }
}
