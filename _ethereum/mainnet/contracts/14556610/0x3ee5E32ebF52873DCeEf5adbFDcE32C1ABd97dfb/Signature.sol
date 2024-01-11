//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

library Signature {

    function split(bytes memory sig) internal pure returns (uint8, bytes32, bytes32)
    {
        require(sig.length == 65, "Signature length not valid");

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

    function recoverSigner(bytes32 message, bytes calldata sig) internal pure returns (address)
    {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = split(sig);

        return ecrecover(message, v, r, s);
    }

    // Builds a prefixed hash to mimic the behavior of eth_sign.
    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
 }