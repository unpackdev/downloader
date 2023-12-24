// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library Commands {

    bytes1 internal constant SIMPLE_TRANSFER = 0x00;
    bytes1 internal constant NATIVE_TRANSFER = 0x01;
    bytes1 internal constant TRANSFER_TO_CONTRACT = 0x02;
    bytes1 internal constant TRANSFER_FROM_CONTRACT = 0x03; // only for taker commands
    bytes1 internal constant TRANSFER_WITH_PERMIT = 0x04; // only for taker commands
    bytes1 internal constant PERMIT_THEN_TRANSFER = 0x05; // only for taker commands
    bytes1 internal constant PERMIT2_THEN_TRANSFER = 0x06; // only for taker commands

}
