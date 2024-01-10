// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./SeenTypes.sol";
import "./IMarketHandler.sol";

/**
 * @title IAuctionBuilder
 *
 * @notice Handles the creation of Seen.Haus auctions.
 *
 * The ERC-165 identifier for this interface is: 0xb147a90b
 *
 * @author Cliff Hall <cliff@futurescale.com> (https://twitter.com/seaofarrows)
 */
interface IAuctionBuilder is IMarketHandler {

    // Events
    event AuctionPending(address indexed consignor, address indexed seller, SeenTypes.Auction auction);

    /**
     * @notice The auction getter
     */
    function getAuction(uint256 _consignmentId) external view returns (SeenTypes.Auction memory);

    /**
     * @notice Create a new primary market auction. (English style)
     *
     * Emits an AuctionPending event
     *
     * Reverts if:
     *  - Consignment doesn't exist
     *  - Consignment has already been marketed
     *  - Auction already exists for consignment
     *  - Start time is in the past
     *
     * @param _consignmentId - the id of the consignment being sold
     * @param _start - the scheduled start time of the auction
     * @param _duration - the scheduled duration of the auction
     * @param _reserve - the reserve price of the auction
     * @param _audience - the initial audience that can participate. See {SeenTypes.Audience}
     * @param _clock - the type of clock used for the auction. See {SeenTypes.Clock}
     */
    function createPrimaryAuction (
        uint256 _consignmentId,
        uint256 _start,
        uint256 _duration,
        uint256 _reserve,
        SeenTypes.Audience _audience,
        SeenTypes.Clock _clock
    ) external;

    /**
     * @notice Create a new secondary market auction
     *
     * Emits an AuctionPending event.
     *
     * Reverts if:
     *  - Contract no approved to transfer seller's tokens
     *  - Seller doesn't own the token balance to be auctioned
     *  - Start time is in the past
     *
     * @param _seller - the current owner of the consignment
     * @param _tokenAddress - the contract address issuing the NFT behind the consignment
     * @param _tokenId - the id of the token being consigned
     * @param _start - the scheduled start time of the auction
     * @param _duration - the scheduled duration of the auction
     * @param _reserve - the reserve price of the auction
     * @param _audience - the initial audience that can participate. See {SeenTypes.Audience}
     * @param _clock - the type of clock used for the auction. See {SeenTypes.Clock}
     */
    function createSecondaryAuction (
        address payable _seller,
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _start,
        uint256 _duration,
        uint256 _reserve,
        SeenTypes.Audience _audience,
        SeenTypes.Clock _clock
    ) external;

}