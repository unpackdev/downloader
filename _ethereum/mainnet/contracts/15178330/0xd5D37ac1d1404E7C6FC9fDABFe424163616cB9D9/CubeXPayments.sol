// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./PaymentSplitter.sol";
import "./Ownable.sol";

contract CubeXPayments is PaymentSplitter, Ownable {
  constructor(address[] memory _payees, uint256[] memory _shares) payable PaymentSplitter(_payees, _shares) {}

  // only owner, fail safe
  function withdraw(address _address) external onlyOwner {
    (bool success, ) = payable(_address).call{value: address(this).balance}("");

    require(success, "Withdraw failed.");
  }
}
