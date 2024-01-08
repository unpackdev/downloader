// SPDX-License-Identifier: GPL-3.0

/**
 * NOTE: This file is a clone of the Zora Media.sol contract from https://github.com/ourzora/core/blob/55b69346b829e88c23b20cdc565123a75fa1339c/contracts/interfaces/IMedia.sol
 *
 * The following have been removed:
 *
 * - `MediaData`
 * - `TokenURIUpdated`
 * - `tokenMetadataURI`
 * - `mint`
 * - `mintWithSig`
 * - `updateTokenURI`
 * - `updateTokenMetadataURI`
 */

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./IMarket.sol";

/**
 * @title Interface for Zora Protocol's Media
 */
interface IMedia {
    struct EIP712Signature {
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    /**
     * @notice Transfer the token with the given ID to a given address.
     * Save the previous owner before the transfer, in case there is a sell-on fee.
     * @dev This can only be called by the auction contract specified at deployment
     */
    function auctionTransfer(uint256 tokenId, address recipient) external;

    /**
     * @notice Set the ask on a piece of media
     */
    function setAsk(uint256 tokenId, IMarket.Ask calldata ask) external;

    /**
     * @notice Remove the ask on a piece of media
     */
    function removeAsk(uint256 tokenId) external;

    /**
     * @notice Set the bid on a piece of media
     */
    function setBid(uint256 tokenId, IMarket.Bid calldata bid) external;

    /**
     * @notice Remove the bid on a piece of media
     */
    function removeBid(uint256 tokenId) external;

    function acceptBid(uint256 tokenId, IMarket.Bid calldata bid) external;

    /**
     * @notice Revoke approval for a piece of media
     */
    function revokeApproval(uint256 tokenId) external;

    /**
     * @notice EIP-712 permit method. Sets an approved spender given a valid signature.
     */
    function permit(
        address spender,
        uint256 tokenId,
        EIP712Signature calldata sig
    ) external;
}
