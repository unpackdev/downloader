// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./PaymentSplitter.sol";
import "./Ownable.sol";

contract BapesClanMetafund is PaymentSplitter, Ownable {
  constructor(address[] memory _payees, uint256[] memory _shares) payable PaymentSplitter(_payees, _shares) {}

  function release(address payable account) public virtual override {
    require(msg.sender == account, "You are not authorized to perform this action.");

    super.release(account);
  }
}
