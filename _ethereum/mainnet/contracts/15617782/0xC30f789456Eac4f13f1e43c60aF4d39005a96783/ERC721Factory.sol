//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Factory.sol";
import "./ERC721Collection.sol";
import "./IERC721Factory.sol";


/**
 * Contract for an ERC-721 factory.
 */
contract ERC721Factory is Factory, IERC721Factory {

    /***************/
    /* Constructor */
    /***************/

    /**
     * Creates a new instance of this contract.
     *
     * @param marketplace_ The configurable marketplace address that will be
     *     given minter role in created collections.
     */
    constructor(address marketplace_) Factory(marketplace_) {}

    /**********************/
    /* External functions */
    /**********************/

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
    )
        external
        nonReentrant
        onlyRole(MINTER_ROLE)
        whenNotPaused
    {
        ERC721Collection collection = new ERC721Collection(
            name,
            symbol,
            msg.sender,
            marketplace()
        );
        emit ERC721CollectionMinted(
            name,
            symbol,
            address(collection),
            msg.sender
        );
    }
}
