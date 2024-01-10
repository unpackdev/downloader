// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./IERC1155Upgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./IAuctionHandler.sol";
import "./IAuctionBuilder.sol";
import "./IAuctionRunner.sol";
import "./ISeenHausNFT.sol";
import "./MarketHandlerBase.sol";

/**
 * @title AuctionBuilderFacet
 *
 * @notice Handles the creation of Seen.Haus auctions.
 *
 * @author Cliff Hall <cliff@futurescale.com> (https://twitter.com/seaofarrows)
 */
contract AuctionBuilderFacet is IAuctionBuilder, MarketHandlerBase {

    // Threshold to auction extension window
    uint256 constant extensionWindow = 15 minutes;

    /**
     * @dev Modifier to protect initializer function from being invoked twice.
     */
    modifier onlyUnInitialized()
    {
        MarketHandlerLib.MarketHandlerInitializers storage mhi = MarketHandlerLib.marketHandlerInitializers();
        require(!mhi.auctionBuilderFacet, "Initializer: contract is already initialized");
        mhi.auctionBuilderFacet = true;
        _;
    }

    /**
     * @notice Facet Initializer
     *
     * Register supported interfaces
     */
    function initialize()
    public
    onlyUnInitialized
    {
        DiamondLib.addSupportedInterface(type(IAuctionBuilder).interfaceId);   // when combined with IAuctionRunner ...
        DiamondLib.addSupportedInterface(type(IAuctionBuilder).interfaceId ^ type(IAuctionRunner).interfaceId);  // ... supports IAuctionHandler
    }

    /**
     * @notice The auction getter
     */
    function getAuction(uint256 _consignmentId)
    external
    view
    override
    returns (Auction memory)
    {

        // Get Market Handler Storage struct
        MarketHandlerLib.MarketHandlerStorage storage mhs = MarketHandlerLib.marketHandlerStorage();

        // Return the auction
        return mhs.auctions[_consignmentId];
    }

    /**
     * @notice Create a new primary market auction. (English style)
     *
     * Emits an AuctionPending event
     *
     * Reverts if:
     *  - Consignment doesn't exist
     *  - Consignment has already been marketed
     *  - Consignment has a supply other than 1
     *  - Auction already exists for consignment
     *  - Duration is less than 15 minutes
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
        Audience _audience,
        Clock _clock
    )
    external
    override
    onlyRole(SELLER)
    onlyConsignor(_consignmentId)
    {
        require(_duration >= extensionWindow, "Duration must be equal to or longer than 15 minutes");

        // Get Market Handler Storage struct
        MarketHandlerLib.MarketHandlerStorage storage mhs = MarketHandlerLib.marketHandlerStorage();

        // Get the consignment (reverting if consignment doesn't exist)
        Consignment memory consignment = getMarketController().getConsignment(_consignmentId);

        // For auctions, ensure that the consignment supply is 1 (we don't facilitate a single auction for multiple tokens)
        require(consignment.supply == 1, "Auctions can only be made with consignments that have a supply of 1");

        // Make sure the consignment hasn't been marketed
        require(consignment.marketHandler == MarketHandler.Unhandled, "Consignment has already been marketed");

        // Get the storage location for the auction
        Auction storage auction = mhs.auctions[consignment.id];

        // Make sure auction doesn't exist (start would always be non-zero on an actual auction)
        require(auction.start == 0, "Auction exists");

        // Make sure start time isn't in the past if the clock type is not trigger type
        // It doesn't matter if the start is in the past if clock type is trigger type
        // Because when the first bid comes in, that gets set to the start time anyway
        if(_clock != Clock.Trigger) {
            require(_start >= block.timestamp, "Non-trigger clock type requires start time in future");
        } else {
            require(_start > 0, "Start time must be more than zero");
        }

        // Set up the auction
        setAudience(_consignmentId, _audience);
        auction.consignmentId = consignment.id;
        auction.start = _start;
        auction.duration = _duration;
        auction.reserve = _reserve;
        auction.clock = _clock;
        auction.state = State.Pending;
        auction.outcome = Outcome.Pending;

        // Notify MarketController the consignment has been marketed
        getMarketController().marketConsignment(consignment.id, MarketHandler.Auction);

        // Notify listeners of state change
        emit AuctionPending(msg.sender, consignment.seller, auction);
    }

    /**
     * @notice Create a new secondary market auction
     *
     * Emits an AuctionPending event.
     *
     * Reverts if:
     *  - This contract not approved to transfer seller's tokens
     *  - Seller doesn't own the asset(s) to be auctioned
     *  - Token contract does not implement either IERC1155 or IERC721
     *  - Duration is less than 15 minutes
     *
     * @param _seller - the address that proceeds of the auction should go to
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
        Audience _audience,
        Clock _clock
    )
    external
    override
    {
        require(_duration >= extensionWindow, "Duration must be equal to or longer than 15 minutes");

        // Get Market Handler Storage struct
        MarketHandlerLib.MarketHandlerStorage storage mhs = MarketHandlerLib.marketHandlerStorage();

        // Get the MarketController
        IMarketController marketController = getMarketController();

        // Determine if consignment is physical
        address nft = marketController.getNft();
        if (nft == _tokenAddress && ISeenHausNFT(nft).isPhysical(_tokenId)) {
            // Is physical NFT, require that msg.sender has ESCROW_AGENT role
            require(checkHasRole(msg.sender, ESCROW_AGENT), "Physical NFT secondary listings require ESCROW_AGENT role");
        } else if (nft != _tokenAddress) {
            // Is external NFT, require that listing external NFTs is enabled
            require(marketController.getAllowExternalTokensOnSecondary(), "Listing external tokens is not currently enabled");
        }

        // Make sure start time isn't in the past if the clock type is not trigger type
        // It doesn't matter if the start is in the past if clock type is trigger type
        // Because when the first bid comes in, that gets set to the start time anyway
        if(_clock != Clock.Trigger) {
            require(_start >= block.timestamp, "Non-trigger clock type requires start time in future");
        } else {
            require(_start > 0, "Start time must be more than zero");
        }

        // Make sure this contract is approved to transfer the token
        // N.B. The following will work because isApprovedForAll has the same signature on both IERC721 and IERC1155
        require(IERC1155Upgradeable(_tokenAddress).isApprovedForAll(msg.sender, address(this)), "Not approved to transfer seller's tokens");

        // To register the consignment, tokens must first be in MarketController's possession
        if (IERC165Upgradeable(_tokenAddress).supportsInterface(type(IERC1155Upgradeable).interfaceId)) {

            // Ensure seller a positive number of tokens
            require(IERC1155Upgradeable(_tokenAddress).balanceOf(msg.sender, _tokenId) > 0, "Seller has zero balance of consigned token");

            // Transfer supply to MarketController
            IERC1155Upgradeable(_tokenAddress).safeTransferFrom(
                msg.sender,
                address(getMarketController()),
                _tokenId,
                1, // Supply is always 1 for auction
                new bytes(0x0)
            );

        } else {

            // Token must be a single token NFT
            require(IERC165Upgradeable(_tokenAddress).supportsInterface(type(IERC721Upgradeable).interfaceId), "Invalid token type");

            // Transfer tokenId to MarketController
            IERC721Upgradeable(_tokenAddress).safeTransferFrom(
                msg.sender,
                address(getMarketController()),
                _tokenId
            );

        }

        // Register consignment
        Consignment memory consignment = getMarketController().registerConsignment(Market.Secondary, msg.sender, _seller, _tokenAddress, _tokenId, 1);
        // Secondaries are marketed directly after registration
        getMarketController().marketConsignment(consignment.id, MarketHandler.Auction);

        // Set up the auction
        setAudience(consignment.id, _audience);
        Auction storage auction = mhs.auctions[consignment.id];
        auction.consignmentId = consignment.id;
        auction.start = _start;
        auction.duration = _duration;
        auction.reserve = _reserve;
        auction.clock = _clock;
        auction.state = State.Pending;
        auction.outcome = Outcome.Pending;

        // Notify listeners of state change
        emit AuctionPending(msg.sender, consignment.seller, auction);

    }

}