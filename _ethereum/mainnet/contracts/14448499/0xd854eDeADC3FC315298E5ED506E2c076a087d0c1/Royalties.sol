// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./PaymentSplitter.sol";

contract Royalties is PaymentSplitter {
    constructor(address[] memory payees, uint256[] memory shares_)
        PaymentSplitter(payees, shares_)
    {}
}
