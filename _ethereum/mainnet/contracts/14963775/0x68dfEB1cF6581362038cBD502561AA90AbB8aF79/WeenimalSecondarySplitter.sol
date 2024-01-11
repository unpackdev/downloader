//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PaymentSplitter.sol";

contract WeenimalSecondarySplitter is PaymentSplitter {
  constructor(address[] memory _payees, uint256[] memory _shares) PaymentSplitter(_payees, _shares){
    
  }

  function pendingPayment(address account) public view returns (uint) {
    return ((address(this).balance + totalReleased()) * shares(account)) / totalShares() - released(account);
  }
}
