// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Withdrawable
 * @author akibe
 */

abstract contract Withdrawable {
  event Withdrawn(address indexed payee, uint256 weiAmount);

  function _withdraw(address payable payee) internal {
    uint256 balance = address(this).balance;
    require(0 < balance, 'Withdrawable: 0 Balance');

    (bool success, ) = payee.call{ value: balance }('');
    require(success, 'Withdrawable: Transfer failed');

    emit Withdrawn(payee, balance);
  }
}
