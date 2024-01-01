// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./IEIP1271.sol";

contract SignatureVerifier {
    // --- Errors ---

    error InvalidSignature();

    // --- Internal methods ---

    function verifySignature(
        address signer,
        bytes32 eip712Hash,
        bytes calldata signature
    ) internal view {
        if (signer.code.length == 0) {
            (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature);

            address actualSigner = ecrecover(eip712Hash, v, r, s);
            if (actualSigner == address(0) || actualSigner != signer) {
                revert InvalidSignature();
            }
        } else {
            if (
                IEIP1271(signer).isValidSignature(eip712Hash, signature) !=
                IEIP1271.isValidSignature.selector
            ) {
                revert InvalidSignature();
            }
        }
    }

    function splitSignature(
        bytes calldata signature
    ) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        uint256 length = signature.length;
        if (length == 65) {
            assembly {
                r := calldataload(signature.offset)
                s := calldataload(add(signature.offset, 0x20))
                v := byte(0, calldataload(add(signature.offset, 0x40)))
            }
        } else if (length == 64) {
            assembly {
                r := calldataload(signature.offset)
                let vs := calldataload(add(signature.offset, 0x20))
                s := and(
                    vs,
                    0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
                )
                v := add(shr(255, vs), 27)
            }
        } else {
            revert InvalidSignature();
        }

        if (
            uint256(s) >
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
        ) {
            revert InvalidSignature();
        }

        if (v != 27 && v != 28) {
            revert InvalidSignature();
        }
    }
}
