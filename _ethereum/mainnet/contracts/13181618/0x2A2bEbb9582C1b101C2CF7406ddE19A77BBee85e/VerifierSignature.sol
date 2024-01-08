// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

/* Signature Verification

How to Sign and Verify
# Signing
1. Create message to sign
2. Hash the message
3. Sign the hash (off chain, keep your private key secret)

# Verify
1. Recreate hash from the original message
2. Recover signer from signature and hash
3. Compare recovered signer to claimed signer
*/

contract VerifierSignature {
    function getSwapMessageHash(
        address token0,
        uint256 token0Amount,
        address token1,
        uint256 token1Amount,
        bytes memory _nonce
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(token0, token0Amount, token1, token1Amount, _nonce));
    }

    function getTransferMessageHash(
        address token0,
        uint256 token0Amount,
        address destination,
        bytes memory _nonce
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(token0, token0Amount, destination, _nonce));
    }

    function getEthSignedMessageHash(bytes32 _messageHash)
        public
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash)
            );
    }

    function verifySwap(
        address _signer,
        address token0,
        uint256 token0Amount,
        address token1,
        uint256 token1Amount,
        bytes memory _nonce,
        bytes memory signature
    ) public pure returns (bool) {
        bytes32 messageHash = getSwapMessageHash(token0, token0Amount, token1, token1Amount, _nonce);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature) == _signer;
    }

    function verifyTransfer(
        address _signer,
        address token0,
        uint256 token0Amount,
        address destination,
        bytes memory _nonce,
        bytes memory signature
    ) public pure returns (bool) {
        bytes32 messageHash = getTransferMessageHash(token0, token0Amount, destination, _nonce);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature) == _signer;
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature)
        public
        pure
        returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        if (v <= 1) {
          v = v + 27;
        }
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        public
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }
}
