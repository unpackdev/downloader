// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity =0.8.4;

import "./PaymentSplitter.sol";

contract SpunksPaymentSplitter is PaymentSplitter {
    constructor(address[] memory payees, uint256[] memory shares) PaymentSplitter(payees, shares) {}
}
