// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "PaymentSplitter.sol";

contract Payments is PaymentSplitter {
    
    constructor (address[] memory _payees, uint256[] memory _shares) PaymentSplitter(_payees, _shares) payable {}
    
}