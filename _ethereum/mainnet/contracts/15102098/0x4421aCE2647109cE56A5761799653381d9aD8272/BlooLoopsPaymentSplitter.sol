// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
_____ _               _            ______    
| ___ \ |             | |           | ___ \   
| |_/ / | ___   ___   | | ___   ___ | |_/ /__ 
| ___ \ |/ _ \ / _ \  | |/ _ \ / _ \|  __/ __|
| |_/ / | (_) | (_) | | | (_) | (_) | |  \__ \
\____/|_|\___/ \___/  |_|\___/ \___/\_|  |___/
                                              
 https://blooloops.io/                                             
                                                                                                         
*/

import "./PaymentSplitter.sol";
import "./Ownable.sol";

contract BlooLoopsPaymentSplitter is PaymentSplitter, Ownable {
  address[] private _payees;

  constructor(address[] memory payees, uint256[] memory shares_) PaymentSplitter(payees, shares_) {
    _payees = payees;
  }

  function flush() public onlyOwner {
    for (uint256 i = 0; i < _payees.length; i++) {
      address addr = _payees[i];
      release(payable(addr));
    }
  }

  function flushToken(IERC20 token) public onlyOwner {
    for (uint256 i = 0; i < _payees.length; i++) {
      address addr = _payees[i];
      release(token, payable(addr));
    }
  }
}