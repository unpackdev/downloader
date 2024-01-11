// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ERC1155TransferableWrapper.sol";

/**
 * @title OpenSeaStorefrontWrapper
 *
 * Note: Transfer wrapper around the ERC1155 OpenSea Storefront contract,
 * to easily enable bulk transfers of tokens to multiple addresses. All
 * functionality is gated to the owner contract, so not usable for spamming.
 */
contract OpenSeaStorefrontWrapper is ERC1155TransferableWrapper {
    constructor()
        ERC1155TransferableWrapper(
            0x495f947276749Ce646f68AC8c248420045cb7b5e // OpenSea Shared Storefront (OPENSTORE): https://etherscan.io/address/0x495f947276749ce646f68ac8c248420045cb7b5e
        )
    {
        // Implementation version: 1
    }
}
