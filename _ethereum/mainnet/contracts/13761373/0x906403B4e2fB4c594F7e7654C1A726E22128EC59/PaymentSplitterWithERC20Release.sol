// SPDX-License-Identifier: MIT
/// @title: Payment Splitter Factory
/// @author: DropHero LLC
pragma solidity ^0.8.0;

import "./PaymentSplitter.sol";
import "./Ownable.sol";
import "./IERC20.sol";

contract PaymentSplitterWithERC20Transfer is Ownable, PaymentSplitter {
  constructor(
    address[] memory payees,
    uint256[] memory paymentShares
  ) PaymentSplitter(payees, paymentShares) {}

  function withdrawERC20(IERC20 tokenAddress, address to) external onlyOwner {
    tokenAddress.transfer(to, tokenAddress.balanceOf((address)(this)));
  }
}
