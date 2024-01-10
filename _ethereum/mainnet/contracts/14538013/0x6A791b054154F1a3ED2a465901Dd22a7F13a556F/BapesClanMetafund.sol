/*** With love from
 *                 _                 _
 *     ___   __ _ | |_  __ _   __ _ (_)
 *    / __| / _` || __|/ _` | / _` || |
 *    \__ \| (_| || |_| (_| || (_| || |
 *    |___/ \__,_| \__|\__,_| \__, ||_|
 *                               |_|
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Address.sol";
import "./Context.sol";

contract BapesClanMetafund is Context, Ownable {
  event PayeeAdded(address account, uint256 shares);
  event PaymentReleased(address to, uint256 amount);
  event PaymentReceived(address from, uint256 amount);

  uint256 private _totalShares = 100;
  uint256 private _totalReleased;
  address payable private _payee;

  constructor(address _account) payable {
    _updatePayee(_account);
  }

  receive() external payable virtual {
    emit PaymentReceived(_msgSender(), msg.value);
  }

  function totalReleased() public view returns (uint256) {
    return _totalReleased;
  }

  function payee() public view returns (address) {
    return _payee;
  }

  function shares() public view returns (uint256) {
    return _totalShares;
  }

  function release(uint256 _amount) public virtual {
    require(msg.sender == _payee, "You are not authorized to perform this action.");
    require(_amount > 0, "Invalid amount");

    uint256 totalReceived = address(this).balance + totalReleased();
    uint256 pendingPayment = totalReceived - totalReleased();

    require(pendingPayment >= _amount, "Not enough balance in contract");

    _totalReleased += _amount;

    Address.sendValue(_payee, _amount);
    emit PaymentReleased(_payee, _amount);
  }

  function _updatePayee(address _account) private {
    require(_account != address(0), "Account is the zero address");

    _payee = payable(_account);

    emit PayeeAdded(_account, _totalShares);
  }
}
