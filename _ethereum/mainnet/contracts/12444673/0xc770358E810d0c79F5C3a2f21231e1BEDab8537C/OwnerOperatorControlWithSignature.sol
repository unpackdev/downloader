// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "./OwnerOperatorControl.sol";

abstract contract OwnerOperatorControlWithSignature is OwnerOperatorControl {
    /**
     * @dev Verify that mint was aknowledge by an operator
     */
    function requireOperatorSignature(
        bytes32 message,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public view {
        require(isOperator(recoverSigner(message, v, r, s)), 'Wrong Signature');
    }

    // for whatever reason I can't get ECDSA.recover to work so let's go old school
    function recoverSigner(
        bytes32 message,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public pure returns (address) {
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
                r,
                s
            );
    }
}
