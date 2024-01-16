//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


/**
 * Represents the external interface of an ERC-721 factory.
 */
interface IERC721Factory {

    /**
     * Mints a new collection.
     *
     * Emits an ERC721CollectionMinted event after completion.
     *
     * @param name The ERC-721 name of the collection.
     * @param symbol The ERC-721 symbol of the collection.
     */
    function mintCollection(
        string calldata name,
        string calldata symbol
    ) external;

    /**
     * Emitted when an ERC-721 collection is minted.
     */
    event ERC721CollectionMinted(
        string name,
        string symbol,
        address collection,
        address creator
    );
}
