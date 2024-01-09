// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

library PartLib {
    bytes32 public constant TYPE_HASH = keccak256("PartData(address account,uint96 value)");

    struct PartData {
        address payable account;
        uint96 value;
    }

    function hash(PartData memory part) internal pure returns (bytes32) {
        return keccak256(abi.encode(TYPE_HASH, part.account, part.value));
    }
}