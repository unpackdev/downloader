// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract MessageSigning {
    /* An ECDSA signature. */
    struct Signature {
        /* v parameter */
        uint8 v;
        /* r parameter */
        bytes32 r;
        /* s parameter */
        bytes32 s;
    }

    /**
     * @dev verifies signature
     */
    function recoverMessageSignature(
        bytes32 message,
        Signature memory signature
    ) public pure returns (address) {
        uint8 v = signature.v;
        if (v < 27) {
            v += 27;
        }

        return
            ecrecover(
                keccak256(
                    abi.encodePacked(
                        '\x19Ethereum Signed Message:\n32',
                        message
                    )
                ),
                v,
                signature.r,
                signature.s
            );
    }
}
