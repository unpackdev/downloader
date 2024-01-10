// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./console.sol";

import "./PaymentSplitter.sol";

contract CollectionPaymentSplitter is PaymentSplitter {
    // solhint wrongly warns about empty constructors, see see https://github.com/protofire/solhint/issues/242
    constructor(address[] memory payees, uint256[] memory shares_)
        PaymentSplitter(payees, shares_)
    {} // solhint-disable-line
}
