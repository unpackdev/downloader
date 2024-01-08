// SPDX-License-Identifier: MIT

pragma solidity >=0.6.11;

struct DelegationDisabled {
    bytes32 eventSig;
    address from;
    address to;
    bytes32 functionId;
}
