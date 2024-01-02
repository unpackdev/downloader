// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./LibPart.sol";

// https://github.com/rarible/protocol-contracts/blob/%40rarible/exchange-v2%400.4.0/exchange-v2/contracts/LibOrderDataV1.sol
library LibOrderDataV1 {
    bytes4 public constant V1 = bytes4(keccak256('V1'));

    struct DataV1 {
        LibPart.Part[] payouts;
        LibPart.Part[] originFees;
    }
}
