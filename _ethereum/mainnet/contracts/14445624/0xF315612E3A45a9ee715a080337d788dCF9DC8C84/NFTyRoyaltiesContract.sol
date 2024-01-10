// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./PaymentSplitter.sol";

contract NFTyRoyaltiesContract is PaymentSplitter {
    constructor (address[] memory _payees, uint256[] memory _shares) PaymentSplitter(_payees, _shares) payable {}

    function getTotalBalance() public view returns (uint) {
        return address(this).balance;
    }
}