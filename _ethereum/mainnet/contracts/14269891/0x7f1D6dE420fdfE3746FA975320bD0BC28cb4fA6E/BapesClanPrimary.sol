// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./PaymentSplitter.sol";
import "./Ownable.sol";

contract BapesClanPrimary is PaymentSplitter, Ownable {
  mapping(address => bool) private allowedWallets;

  constructor(address[] memory _payees, uint256[] memory _shares) payable PaymentSplitter(_payees, _shares) {}

  function allowWallets(address[] calldata _wallets) public onlyOwner {
    for (uint256 i = 0; i < _wallets.length; i++) {
      allowedWallets[_wallets[i]] = true;
    }
  }

  function release(address payable account) public virtual override {
    require(allowedWallets[msg.sender], "You are not authorized to perform this action.");

    super.release(account);
  }
}
