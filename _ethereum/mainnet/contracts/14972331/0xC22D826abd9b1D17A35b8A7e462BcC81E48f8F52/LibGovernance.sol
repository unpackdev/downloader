// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;


library LibGovernance {
    bytes32 constant _MINT_PACKED_TYPEHASH = 0x3f51e172eac209b5c99a91c13ae7a166bcd49d068af4f27f3aa08d4c6268e204;

    struct AccountCursor {
        uint checkpoint;
        uint nonce;
    }

    struct MintPacked {
        address account;
        uint checkpoint;
        uint volume;
        uint nonce;
    }

    struct MintExecution {
        MintPacked p;
        bytes sig;
    }

    function recover(MintExecution memory exec, bytes32 domainSeparator) internal pure returns (address) {
        MintPacked memory packed = exec.p;
        bytes memory signature = exec.sig;
        require(signature.length == 65, "invalid signature length");

        bytes32 structHash;
        bytes32 digest;

        // MintPacked struct (4 fields) and type hash (4 + 1) * 32 = 160
        assembly {
            let dataStart := sub(packed, 32)
            let temp := mload(dataStart)
            mstore(dataStart, _MINT_PACKED_TYPEHASH)
            structHash := keccak256(dataStart, 160)
            mstore(dataStart, temp)
        }

        assembly {
            let freeMemoryPointer := mload(0x40)
            mstore(freeMemoryPointer, "\x19\x01")
            mstore(add(freeMemoryPointer, 2), domainSeparator)
            mstore(add(freeMemoryPointer, 34), structHash)
            digest := keccak256(freeMemoryPointer, 66)
        }

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "invalid signature 's' value");

        address signer;

        if (v > 30) {
            require(v - 4 == 27 || v - 4 == 28, "invalid signature 'v' value");
            signer = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", digest)), v - 4, r, s);
        } else {
            require(v == 27 || v == 28, "invalid signature 'v' value");
            signer = ecrecover(digest, v, r, s);
        }
        return signer;
    }
}
