// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

abstract contract GluwacoinBase {
    /**
     * @dev Value of the different domains of signature.
     */
    uint8 internal constant _GENERIC_SIG_BURN_DOMAIN = 1;
    // uint8 internal constant _GENERIC_SIG_MINT_DOMAIN = 2; // Legacy signature, put as placeholder
    uint8 internal constant _GENERIC_SIG_TRANSFER_DOMAIN = 3;
    uint8 internal constant _GENERIC_SIG_RESERVE_DOMAIN = 4;
}
