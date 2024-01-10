// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";

contract WithdrawalProxy is Ownable {
  mapping(address => uint256) public taxRate;

  function withdraw(address withdrawAddress, uint256 withdrawAmount) external payable {
    require(withdrawAmount == msg.value);
    // transfer the post tax amount to the withdraw address
    uint256 postTaxAmount = withdrawAmount - ((withdrawAmount * taxRate[msg.sender]) / 1e5);
    (bool sent, ) = payable(withdrawAddress).call{ value: postTaxAmount }("");
    require(sent, "Failed to send Ether");
  }

  function setTaxRate(address projectAddress, uint256 _taxRate) external onlyOwner {
    taxRate[projectAddress] = _taxRate; // set the tax rate for the project, x 10000
  }

  function withdrawTax(address withdrawAddress) external onlyOwner {
    (bool sent, ) = payable(withdrawAddress).call{ value: address(this).balance }("");
    require(sent, "Failed to send Ether");
  }
}
