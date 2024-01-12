// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library Signatures {
    function recoverSigner(bytes memory sig, bytes32 messageHash)
        internal
        pure
        returns (address)
    {
        uint8 v;
        bytes32 r;
        bytes32 s;
        (v, r, s) = splitSignature(sig);
        
        return ecrecover(messageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            uint8 v,
            bytes32 r,
            bytes32 s
        )
    {
        require(sig.length == 65);
        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }
    }

    function verifySignature(
        bytes memory sig,
        bytes32 message,
        address signer
    ) internal pure returns (bool) {
        bytes32 hash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", message)
        );

        address recovered = recoverSigner(sig, hash);

        return recovered == signer;
    }
}
