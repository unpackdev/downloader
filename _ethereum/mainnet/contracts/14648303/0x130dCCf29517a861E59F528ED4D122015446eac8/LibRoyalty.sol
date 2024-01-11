// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

library LibRoyalty {
    bytes32 public constant TYPE_HASH =
        keccak256("Royalty(address account,uint96 value)");

    struct Royalty {
        address payable account;
        uint96 value;
    }

    function hash(Royalty memory royalty) internal pure returns (bytes32) {
        return keccak256(abi.encode(TYPE_HASH, royalty.account, royalty.value));
    }
}
