// SPDX-License-Identifier: MIT

pragma solidity >=0.6.11;

struct DelegationEnabled {
    bytes32 eventSig;
    address from;
    address to;
    bytes32 functionId;
}
