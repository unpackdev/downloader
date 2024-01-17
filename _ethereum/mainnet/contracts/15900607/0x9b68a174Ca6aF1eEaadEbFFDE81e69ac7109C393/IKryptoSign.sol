// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IKryptoSign {
    struct Document {
        string ipfs;
        address owner;
    }

    struct Signature {
        string ipfs;
        address signer;
        bytes signature;
    }

    event DocumentCreated(bytes32 indexed documentId, address indexed owner);
    event DocumentSigned(bytes32 indexed documentId, address indexed signer);
}
