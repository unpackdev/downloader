//SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

interface IHub {
    enum LotStatus {
        NO_LOT,
        LOT_REQUESTED,
        LOT_CREATED,
        AUCTION_ACTIVE,
        AUCTION_RESOLVED,
        AUCTION_RESOLVED_AND_CLAIMED,
        AUCTION_CANCELED
    }

    // -----------------------------------------------------------------------
    // NON-MODIFYING FUNCTIONS (VIEW)
    // -----------------------------------------------------------------------

    function getLotInformation(uint256 _lotID)
        external
        view
        returns (
            address owner,
            uint256 tokenID,
            uint256 auctionID,
            LotStatus status
        );

    function getAuctionInformation(uint256 _auctionID)
        external
        view
        returns (
            bool active,
            string memory auctionName,
            address auctionContract,
            bool onlyPrimarySales
        );

    function getAuctionID(address _auction) external view returns (uint256);

    function isAuctionActive(uint256 _auctionID) external view returns (bool);

    function getAuctionCount() external view returns (uint256);

    function isAuctionHubImplementation() external view returns (bool);

    function isFirstSale(uint256 _tokenID) external view returns (bool);

    function getFirstSaleSplit()
        external
        view
        returns (uint256 creatorSplit, uint256 systemSplit);

    function getSecondarySaleSplits()
        external
        view
        returns (
            uint256 creatorSplit,
            uint256 sellerSplit,
            uint256 systemSplit
        );

    function getScalingFactor() external view returns (uint256);

    // -----------------------------------------------------------------------
    // PUBLIC STATE MODIFYING FUNCTIONS
    // -----------------------------------------------------------------------

    function requestAuctionLot(uint256 _auctionType, uint256 _tokenID)
        external
        returns (uint256 lotID);

    // -----------------------------------------------------------------------
    // ONLY AUCTIONS STATE MODIFYING FUNCTIONS
    // -----------------------------------------------------------------------

    function firstSaleCompleted(uint256 _tokenID) external;

    function lotCreated(uint256 _auctionID, uint256 _lotID) external;

    function lotAuctionStarted(uint256 _auctionID, uint256 _lotID) external;

    function lotAuctionCompleted(uint256 _auctionID, uint256 _lotID) external;

    function lotAuctionCompletedAndClaimed(uint256 _auctionID, uint256 _lotID)
        external;

    function cancelLot(uint256 _auctionID, uint256 _lotID) external;

    // -----------------------------------------------------------------------
    // ONLY REGISTRY STATE MODIFYING FUNCTIONS
    // -----------------------------------------------------------------------

    function init() external returns (bool);
}
