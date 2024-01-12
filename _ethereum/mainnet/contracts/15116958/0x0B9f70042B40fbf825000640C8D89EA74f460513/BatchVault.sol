/**
 *Submitted for verification at Etherscan.io on 2021-05-25
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma abicoder v2;

import "./Ownable.sol";
import "./Pausable.sol";

contract BatchVault is Ownable, Pausable {
  event PaymentReceived(address indexed _payer, uint256 _value);

  // solhint-disable-next-line func-visibility, no-empty-blocks
  constructor() {}

  receive() external payable {
    emit PaymentReceived(msg.sender, msg.value);
  }

  // Ottengo il balance dello smart contract
  function getVaultBalance() public view onlyOwner whenNotPaused returns (uint256) {
    return address(this).balance;
  }

  // Sposto il balance dello smart contract
  function sendVaultBalance(uint256 _amount, address payable _receiver) public onlyOwner whenNotPaused {
    require(address(this).balance >= _amount, "Not enought WEI in the balance");
    _receiver.transfer(_amount);
  }
}
