// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

/**
 * @title Events and errors for Hunab.
 */
abstract contract HunabEventsAndErrors {
    /**
     * Emitted when redemption completed.
     * @param tokenId The id of the redeemed token
     * @param newTokenId The id of the new token
     * @param extractedFund The extracted fund during redemption
     */
    event Redeemed(
        uint256 indexed tokenId,
        uint256 indexed newTokenId,
        uint256 extractedFund
    );

    /**
     * Auth mint is not enabled.
     */
    error AuthMintNotEnabled();

    /**
     * Public mint is not enabled.
     */
    error PublicMintNotEnabled();

    /**
     * Redemption is not enabled.
     */
    error RedemptionNotEnabled();

    /**
     * The account is not authorized.
     */
    error NotAuthorized();

    /**
     * Maximum auth mint limit per wallet exceeded.
     */
    error MaxAuthMintPerWalletExceeded();

    /**
     * Maximum auth mint limit exceeded.
     */
    error MaxAuthMintExceeded();

    /**
     * The account is not the token owner.
     */
    error NotTokenOwner();

    /**
     * Insufficient value.
     */
    error InsufficientValue();

    /**
     * Invalid params.
     */
    error InvalidParams();

    /**
     * Invalid token id.
     */
    error InvalidTokenId();
}
