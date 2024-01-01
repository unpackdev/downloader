// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

import "./ECDSA.sol";

/**
 * @dev Signature verification
 */
library Validate {
    using ECDSA for bytes32;

    /**
     * @dev Throws if given `sig` is an incorrect signature of the `sender`.
     */
    function _validateSignature(
        bytes32 hash_,
        address sender,
        bytes calldata sig
    ) internal pure returns (bool) {
        require(
            ECDSA.recover(hash_, sig) == sender,
            "Validate: invalid signature"
        );
        return true;
    }
}
