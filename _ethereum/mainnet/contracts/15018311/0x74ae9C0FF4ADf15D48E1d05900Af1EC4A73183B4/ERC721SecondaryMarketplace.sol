//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SecondaryMarketplace.sol";
import "./ERC721Collection.sol";


/**
 * Contract for an ERC-721 secondary marketplace.
 */
contract ERC721SecondaryMarketplace is SecondaryMarketplace {

    /***************/
    /* Constructor */
    /***************/

    /**
     * Creates a new instance of this contract.
     *
     * @param name The EIP-712 name of the contract used when verifying signed
     *     transaction messages.
     * @param version The EIP-712 version of the contract used when verifying
     *     signed transaction messages.
     * @param validator_ The configurable validator address that will be used
     *     when verifying signed transaction messages.
     * @param commissionNumerator_ The configurable commission numerator that
     *     will be used for calculating the commission amount of a transaction.
     * @param maxRoyaltyNumerator_ The configurable maximum royalty numerator
     *     that will be used for verifying the royalty numerator of a
     *     transaction.
     */
    constructor(
        string memory name,
        string memory version,
        address validator_,
        uint16 commissionNumerator_,
        uint16 maxRoyaltyNumerator_
    )
        Marketplace(
            name,
            version,
            validator_,
            commissionNumerator_,
            maxRoyaltyNumerator_
        )
    {}

    /**********************/
    /* Internal functions */
    /**********************/

    /**
     * Transfers an existing token to the buyer.
     *
     * @param message the Transaction message.
     */
    function _transferToken(TransactionMessage calldata message)
        internal
        override
    {
        ERC721Collection(message.collection).safeTransferFrom(
            message.seller,
            message.buyer,
            message.tokenId
        );
    }

    /**
     * Abstract internal function responsible for verifying if the seller is
     * the owner of the token being sold.
     *
     * @param message The transaction message.
     * @return Whether or not the seller is the owner of the token being sold.
     */
    function _verifySellerIsOwner(TransactionMessage calldata message)
        internal
        view
        override
        returns (bool)
    {
        return ERC721Collection(
            message.collection
        ).ownerOf(message.tokenId) == message.seller;
    }
}
