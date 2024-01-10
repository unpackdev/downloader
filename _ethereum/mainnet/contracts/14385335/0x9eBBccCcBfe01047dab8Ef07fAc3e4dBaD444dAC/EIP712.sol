// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title EIP712
/// @author 0xAd1
/// @notice Used to verify signatures
contract EIP712 {

    /// @notice Verifies a signature against alleged signer of the signature
    /// @param signature Signature to verify
    /// @param authority Signer of the signature
    /// @return True if the signature is signed by authority
    function verifySignatureAgainstAuthority(
        bytes memory signature,
        address authority
    ) internal returns (bool){
        bytes32 eip712DomainHash = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes("Batcher")),
                keccak256(bytes("1")),
                1, 
                address(this)
            )
        );

        bytes32 hashStruct = keccak256(
            abi.encode(
                keccak256("deposit(address owner)"),
                msg.sender
            )
        );

        (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature);

        bytes32 hash = keccak256(abi.encodePacked("\x19\x01", eip712DomainHash, hashStruct));
        address signer = ecrecover(hash, v, r, s);
        require(signer == authority, "Invalid authority");
        require(signer != address(0), "ECDSA: invalid signature");
        return true;
    }

    function splitSignature(bytes memory sig)
        internal
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