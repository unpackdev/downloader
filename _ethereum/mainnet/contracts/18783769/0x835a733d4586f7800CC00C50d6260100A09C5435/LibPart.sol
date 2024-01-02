// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// https://github.com/rarible/protocol-contracts/blob/%40rarible/exchange-v2%400.4.0/royalties/contracts/LibPart.sol
library LibPart {
    struct Part {
        address payable account;
        uint96 value;
    }
}
