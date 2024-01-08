// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;


interface IAuctions {

    struct House {
        // House name
        string  name;

        // House curator
        address payable curator;

        // House percentage fee
        uint16  fee;

        // Pre-approve added creators
        bool    preApproved;

        // IPFS hash for metadata (logo, featured creators, pieces, links)
        string  metadata;

        // Total bids
        uint256 bids;

        // Total sales number
        uint256 sales;

        // Total sales amount
        uint256 total;

        // Total fees amount
        uint256 feesTotal;

        // Counter of active autions
        uint256 activeAuctions;

        // Rank
        uint256 rank;
    }

    struct Auction {
        // Address of the ERC721 contract
        address tokenContract;

        // ERC721 tokenId
        uint256 tokenId;

        // Address of the token owner
        address tokenOwner;

        // Length of time in seconds to run the auction for, after the first bid was made
        uint256 duration;

        // Minimum price of the first bid
        uint256 reservePrice;

        // House ID for curator address
        uint256 houseId;

        // Curator fee for this auction
        uint16  fee;

        // Whether or not the auction curator has approved the auction to start
        bool    approved;

        // The time of the first bid
        uint256 firstBidTime;

        // The current highest bid amount
        uint256 amount;

        // The address of the current highest bidder
        address payable bidder;

        // The timestamp when this auction was created
        uint256 created;
    }

    struct TokenContract {
        string  name;
        address tokenContract;
        uint256 bids;
        uint256 sales;
        uint256 total;
        uint256 rank;
    }

    struct Account {
        string  name;
        string  bioHash;
        string  pictureHash;
        uint256 creatorRank;
        uint256 collectorRank;
    }

    struct CreatorStats {
        uint256 bids;
        uint256 sales;
        uint256 total;
    }

    struct CollectorStats {
        uint256 bids;
        uint256 sales;
        uint256 bought;
        uint256 totalSold;
        uint256 totalSpent;
    }

    struct Bid {
        uint256 timestamp;
        address bidder;
        uint256 value;
    }

    struct Offer {
        address tokenContract;
        uint256 tokenId;
        uint256 amount;
        address from;
    }

    event HouseCreated(
        uint256 indexed houseId
    );

    event CreatorAdded(
        uint256 indexed houseId,
        address indexed creator
    );

    event CreatorRemoved(
        uint256 indexed houseId,
        address indexed creator
    );

    event FeeUpdated(
        uint256 indexed houseId,
        uint16  fee
    );

    event MetadataUpdated(
        uint256 indexed houseId,
        string  metadata
    );

    event AccountUpdated(
        address indexed owner
    );

    event AuctionCreated(
        uint256 indexed auctionId
    );

    event AuctionApprovalUpdated(
        uint256 indexed auctionId,
        bool    approved
    );

    event AuctionReservePriceUpdated(
        uint256 indexed auctionId,
        uint256 reservePrice
    );

    event AuctionBid(
        uint256 indexed auctionId,
        address bidder,
        uint256 value,
        bool    firstBid,
        bool    extended
    );

    event AuctionDurationExtended(
        uint256 indexed auctionId,
        uint256 duration
    );

    event AuctionEnded(
        uint256 indexed auctionId
    );

    event AuctionCanceled(
        uint256 indexed auctionId
    );

    function totalHouses() external view returns (uint256);

    function totalAuctions() external view returns (uint256);

    function totalContracts() external view returns (uint256);

    function totalCreators() external view returns (uint256);

    function totalCollectors() external view returns (uint256);

    function totalActiveAuctions() external view returns (uint256);

    function totalActiveHouseAuctions(uint256 houseId) external view returns (uint256);

    function getAuctions() external view returns (uint256[] memory);

    function getAuctionsFromN(uint256 from, uint256 n) external view returns (uint256[] memory);

    function getHouseAuctions(uint256 houseId) external view returns (uint256[] memory);

    function getHouseAuctionsFromN(uint256 houseId, uint256 from, uint256 n) external view returns (uint256[] memory);

    function getHouseQueue(uint256 houseId) external view returns (uint256[] memory);

    function getCuratorHouses(address curator) external view returns (uint256[] memory);

    function getCreatorHouses(address creator) external view returns (uint256[] memory);

    function getHouseCreators(uint256 houseId) external view returns (address[] memory);

    function getSellerAuctions(address seller) external view returns (uint256[] memory);

    function getBidderAuctions(address bidder) external view returns (uint256[] memory);

    function getAuctionBids(uint256 auctionId) external view returns (uint256[] memory);

    function getPreviousAuctions(bytes32 tokenHash) external view returns (uint256[] memory);

    function getTokenOffers(bytes32 tokenHash) external view returns (uint256[] memory);

    function registerTokenContract(
        address tokenContract
    ) external returns (uint256);

    function makeOffer(
        address tokenContract,
        uint256 tokenId,
        uint256 amount
    ) external payable;

    function acceptOffer(
        uint256 offerId
    ) external;

    function cancelOffer(
        uint256 offerId
    ) external;

    function createHouse(
        string  memory name,
        address curator,
        uint16  fee,
        bool    preApproved,
        string  memory metadata
    ) external returns (uint256);

    function addCreator(
        uint256 houseId,
        address creator
    ) external;

    function removeCreator(
        uint256 houseId,
        address creator
    ) external;

    function updateMetadata(
        uint256 houseId,
        string  memory metadata
    ) external;

    function updateFee(
        uint256 houseId,
        uint16  fee
    ) external;

    function updateName(
        string  memory name
    ) external;

    function updateBio(
        string  memory bioHash
    ) external;

    function updatePicture(
        string  memory pictureHash
    ) external;

    function createAuction(
        address tokenContract,
        uint256 tokenId,
        uint256 duration,
        uint256 reservePrice,
        uint256 houseId
    ) external returns (uint256);

    function setAuctionApproval(
        uint256 auctionId,
        bool approved
    ) external;

    function setAuctionReservePrice(
        uint256 auctionId,
        uint256 reservePrice
    ) external;

    function createBid(
        uint256 auctionId,
        uint256 amount
    ) external payable;

    function endAuction(
        uint256 auctionId
    ) external;

    function cancelAuction(
        uint256 auctionId
    ) external;
}
