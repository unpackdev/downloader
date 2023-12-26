// SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;

// handles the signed messages
contract SignedMessages {
    /* SIGNATURE SAFETY */

    /// builds a prefixed hash to mimic the behavior of eth_sign.
    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }

    struct Pass{
        bytes32 message;
        bytes sig;
        address issuer;
    }

    function consumePass(
        Pass memory pass
    ) pure internal returns (bool) {
        // check the issuer
        if (pass.issuer != recoverSigner(pass.message, pass.sig)) {
            return false;
        }
        return true;
    }

    function recoverSigner(
        bytes32 _message,
        bytes memory sig
    ) internal pure returns (address) {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = splitSignature(sig);

        return ecrecover(_message, v, r, s);
    }

    function splitSignature(
        bytes memory sig
    ) internal pure returns (uint8, bytes32, bytes32) {
        require(sig.length == 65, "error in message length");

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
}
