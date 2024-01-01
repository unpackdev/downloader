//SPDX-License-Identifier: MIT

pragma solidity >=0.8.14;

interface Structs {
    struct EIP712Domain {
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
    }

    struct ProofData {
        address account;
        uint256 nonce;
        uint256 timestamp;
        address destination;
    }

    struct Proof {
        bytes32 s;
        bytes32 r;
        uint8 v;
        ProofData data;
    }
}
