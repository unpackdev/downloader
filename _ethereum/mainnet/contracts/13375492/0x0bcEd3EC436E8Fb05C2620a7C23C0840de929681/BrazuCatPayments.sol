// SPDX-License-Identifier: GPL-3.0

// Amended by HashLips
/**
    !Disclaimer!
    These contracts have been used to create tutorials,
    and was created for the purpose to teach people
    how to create smart contracts on the blockchain.
    please review this code on your own before using any of
    the following code for production.
    HashLips will not be liable in any way if for the use 
    of the code. That being said, the code has been tested 
    to the best of the developers' knowledge to work as intended.
*/

pragma solidity ^0.8.0;

import "./PaymentSplitter.sol";

contract BrazuCatPayments is PaymentSplitter {
    
    constructor (address[] memory _payees, uint256[] memory _shares) PaymentSplitter(_payees, _shares) payable {}
    
}

/**
 
 0xd9c681F4c61B8E5B8Aed276458C7b6f3E14ea318 - tuba
 0x3445735b5A0402AeAa4e2Dc4993f11FF7eA60B32 - guiigss
 0x4C29915Da778879e475E62B5e09a692B095F96Cb - bar
 0xe25b4fDF5CCA6CEA3D705beb55FAB9A1BA8b1879 - d3n4um
 0x9dbfba33d8ad708b7e0e3beae053d2c8d6b063ca - donation

[30, 25, 15, 10, 10]
 */