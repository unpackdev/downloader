// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
pragma solidity 0.8.19;

contract CrossChainFunctions {
    uint8 internal constant WRITE_OBLIGATIONS = 0;
    uint8 internal constant REJECT_DEPOSITS = 1;

    struct CrossChainMessage {
        uint8 instruction;
        bytes payload;
    }
}
