// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SafeERC20.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./Context.sol";

contract AmbassadorsFund is Context, Ownable {
  event PayeeAdded(address account, uint256 shares);
  event PaymentReleased(address to, uint256 amount);
  event ERC20PaymentReleased(IERC20 indexed token, address to, uint256 amount);
  event PaymentReceived(address from, uint256 amount);

  uint256 private _totalShares;
  uint256 private _totalReleased;

  mapping(address => uint256) private _shares;
  mapping(address => uint256) private _released;
  address[] private _payees;

  mapping(IERC20 => uint256) private _erc20TotalReleased;
  mapping(IERC20 => mapping(address => uint256)) private _erc20Released;

  constructor(address[] memory payees, uint256[] memory shares_) payable {
    require(payees.length == shares_.length, "PaymentSplitter: payees and shares length mismatch");
    require(payees.length > 0, "PaymentSplitter: no payees");

    for (uint256 i = 0; i < payees.length; i++) {
      _addPayee(payees[i], shares_[i]);
    }
  }

  receive() external payable virtual {
    emit PaymentReceived(_msgSender(), msg.value);
  }

  function totalShares() public view returns (uint256) {
    return _totalShares;
  }

  function totalReleased() public view returns (uint256) {
    return _totalReleased;
  }

  function totalReleased(IERC20 token) public view returns (uint256) {
    return _erc20TotalReleased[token];
  }

  function shares(address account) public view returns (uint256) {
    return _shares[account];
  }

  function released(address account) public view returns (uint256) {
    return _released[account];
  }

  function released(IERC20 token, address account) public view returns (uint256) {
    return _erc20Released[token][account];
  }

  function payee(uint256 index) public view returns (address) {
    return _payees[index];
  }

  function release(address payable account) public virtual {
    require(msg.sender == account, "You are not authorized to perform this action.");
    require(_shares[account] > 0, "PaymentSplitter: account has no shares");

    uint256 totalReceived = address(this).balance + totalReleased();
    uint256 payment = _pendingPayment(account, totalReceived, released(account));

    require(payment != 0, "PaymentSplitter: account is not due payment");

    _released[account] += payment;
    _totalReleased += payment;

    Address.sendValue(account, payment);
    emit PaymentReleased(account, payment);
  }

  function release(IERC20 token, address account) public virtual {
    require(_shares[account] > 0, "PaymentSplitter: account has no shares");

    uint256 totalReceived = token.balanceOf(address(this)) + totalReleased(token);
    uint256 payment = _pendingPayment(account, totalReceived, released(token, account));

    require(payment != 0, "PaymentSplitter: account is not due payment");

    _erc20Released[token][account] += payment;
    _erc20TotalReleased[token] += payment;

    SafeERC20.safeTransfer(token, account, payment);
    emit ERC20PaymentReleased(token, account, payment);
  }

  function _pendingPayment(
    address account,
    uint256 totalReceived,
    uint256 alreadyReleased
  ) private view returns (uint256) {
    uint256 percent = (totalReceived * _shares[account]) / 1000;

    return percent - alreadyReleased;
  }

  function _addPayee(address account, uint256 shares_) private {
    require(account != address(0), "PaymentSplitter: account is the zero address");
    require(shares_ > 0, "PaymentSplitter: shares are 0");
    require(_shares[account] == 0, "PaymentSplitter: account already has shares");

    _payees.push(account);
    _shares[account] = shares_;
    _totalShares = _totalShares + shares_;
    emit PayeeAdded(account, shares_);
  }
}
