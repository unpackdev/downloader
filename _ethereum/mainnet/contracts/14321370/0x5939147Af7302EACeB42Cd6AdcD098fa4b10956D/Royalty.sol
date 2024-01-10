// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "./PaymentSplitter.sol";


contract Royalty is PaymentSplitter {
    
    constructor (address[] memory _payees, uint256[] memory _shares) PaymentSplitter(_payees, _shares) payable {}
    
}

/**
 ["0x5B38Da6a701c568545dCfcB03FcB875f56beddC4", 
 "0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2",
 "0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c"]
 */
 
 /**
 [20, 
 40,
 40]
 */