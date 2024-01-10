// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ReentrancyGuard.sol";
import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./ERC165.sol";

contract NFPeace is
    ERC165,
    IERC721Receiver,
    IERC1155Receiver,
    ReentrancyGuard
{
    /// @notice Unchain (https://unchain.fund) is a charity project created by blockchain activists. Its goal is to break the chain of war which the Russian Federation started against Ukraine.
    /// @dev The wallet address of the humanitarian relief fund unchain.fund
    address payable public constant CHARITY_ADDRESS = payable(0x10E1439455BD2624878b243819E31CfEE9eb721C);

    /// @notice Minimum auction duration after a bid in seconds (15 minutes).
    /// @dev Minimum auction runtime in seconds after new bids
    uint32 public constant BIDDING_GRACE_PERIOD = 15 minutes;

    /// @notice Each bid has to increase by at least 10%
    /// @dev The minimum percentage increase per bid
    uint32 public constant BID_PERCENTAGE_INCREASE = 10;

    /// @dev The minimum value of an auction
    uint64 public constant DEFAULT_STARTING_PRICE = 0.05 ether;

    /// @dev The next auction ID
    uint64 public nextAuctionId = 0;

    struct Auction {
        address tokenContract;
        uint256 tokenId;
        address latestBidder;
        uint128 latestBid;
        uint64 startingPrice; // max ~18.44 Ether
        uint32 endTimestamp; // latest date is Sun Feb 07 2106 06:28:15 GMT (in 84 years)
        uint16 tokenERCStandard;
        uint8 tokenAmount;
        bool settled;
    }

    /// @dev Each auction is identified by an ID
    mapping(uint256 => Auction) private _auctions;

    /// @dev Emitted when an NFT is sent to the contract.
    event AuctionInitialised(uint64 indexed auctionId);

    /// @dev Emitted when a new bid is entered.
    event Bid(uint64 indexed auctionId, uint256 indexed bid, address indexed from);

    /// @dev Emitted when a new bid is entered within the BIDDING_GRACE_PERIOD.
    event AuctionExtended(uint64 indexed auctionId, uint256 indexed endTimestamp);

    /// @dev Emitted when an auction is settled, the NFT is sent to the winner and the funds sent to the charity.
    event AuctionSettled(uint64 indexed auctionId);

    /// @dev Get an Auction by its ID
    function getAuction (uint64 auctionId)
        public view
        returns (
            address tokenContract,
            uint256 tokenId,
            address latestBidder,
            uint128 latestBid,
            uint64 startingPrice,
            uint32 endTimestamp,
            uint16 tokenERCStandard,
            uint8 tokenAmount,
            bool settled
    ) {
        Auction memory auction = _auctions[auctionId];

        return (
            auction.tokenContract,
            auction.tokenId,
            auction.latestBidder,
            auction.latestBid,
            auction.startingPrice,
            auction.endTimestamp,
            auction.tokenERCStandard,
            auction.tokenAmount,
            auction.settled
        );
    }

    /// @dev The minimum value of the next bid for an auction.
    function currentBidPrice (uint64 auctionId)
        external view
        returns (uint128)
    {
        return _currentBidPrice(_auctions[auctionId]);
    }

    /// @dev Enter a new bid
    /// @param auctionId The Auction ID to bid on
    function bid (uint64 auctionId)
        external payable
        nonReentrant
    {
        Auction storage auction = _auctions[auctionId];
        uint256 bidValue = msg.value;
        address bidder = msg.sender;

        require(bidValue >= _currentBidPrice(auction), "Minimum bid value not met.");
        require(block.timestamp <= auction.endTimestamp, "Auction is not active.");

        // Pay back previous bidder
        if (_hasBid(auction)) {
            payable(auction.latestBidder).transfer(auction.latestBid);
        }

        _maybeExtendTime(auctionId, auction);

        // Store the bid
        auction.latestBid = uint128(bidValue);
        auction.latestBidder = bidder;

        emit Bid(auctionId, bidValue, bidder);
    }

    /// @dev Settles an auction
    /// @param auctionId The Auction ID to claim.
    function settle (uint64 auctionId) external {
        Auction storage auction = _auctions[auctionId];
        require(!auction.settled, "Auction already settled.");
        require(auction.endTimestamp > 0, "Auction does not exist.");
        require(block.timestamp > auction.endTimestamp, "Auction not complete.");

        if (_hasBid(auction)) {
            (bool success,) = CHARITY_ADDRESS.call{ value: auction.latestBid }("");
            require(success, "Failed to forward funds");
        }

        if (auction.tokenERCStandard == 721) {
            IERC721(auction.tokenContract).safeTransferFrom(address(this), auction.latestBidder, auction.tokenId, "");
        } else if (auction.tokenERCStandard == 1155) {
            IERC1155(auction.tokenContract).safeTransferFrom(address(this), auction.latestBidder, auction.tokenId, auction.tokenAmount, "");
        }

        // End the auction
        auction.settled = true;
        emit AuctionSettled(auctionId);
    }

    /// @dev Hook for `saveTransferFrom` of ERC721 tokens to this contract
    /// @param from The address which previously owned the token
    /// @param tokenId The ID of the token being transferred
    /// @param data The custom starting price (set by a user)
    function onERC721Received(
        address,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) public override returns (bytes4) {
        _initializeAuction(tokenId, 721, from, _getStartingPrice(data), 1);

        return IERC721Receiver.onERC721Received.selector;
    }

    /// @dev Hook for `saveTransferFrom` of ERC1155 tokens to this contract
    /// @param from The address which previously owned the token
    /// @param id The ID of the token being transferred
    /// @param value The amount of tokens being transferred
    /// @param data The custom starting price (set by a user)
    function onERC1155Received(
        address,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) public override returns (bytes4) {
        require(value < 256, "Too many tokens");

        _initializeAuction(id, 1155, from, _getStartingPrice(data), uint8(value));

        return IERC1155Receiver.onERC1155Received.selector;
    }

    /// @dev Hook for `safeBatchTransferFrom` of ERC1155 tokens to this contract
    /// @param operator The address which initiated the transfer
    /// @param from The address which previously owned the token
    /// @param ids An array containing ids of each token being transferred (order and length must match values array)
    /// @param values An array containing amounts of each token being transferred (order and length must match ids array)
    /// @param data The custom starting price (set by a user)
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external override returns (bytes4) {
        for (uint256 index = 0; index < ids.length; index++) {
            onERC1155Received(operator, from, ids[index], values[index], data);
        }

        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }

    /// @dev Get the starting price based on default or user input. Warns users about out of range price.
    function _getStartingPrice (bytes calldata data) internal pure returns (uint64) {
        uint64 price = toUint64(data);

        return price > DEFAULT_STARTING_PRICE ? price : DEFAULT_STARTING_PRICE;
    }

    /// @dev Initializes an auction
    function _initializeAuction (
        uint256 tokenId,
        uint16 tokenERCStandard,
        address tokenOwner,
        uint64 startingPrice,
        uint8 tokenAmount
    ) internal
    {
        _auctions[nextAuctionId] = Auction(
            msg.sender,                          // the NFT token contract
            tokenId,                             // the NFT token ID
            tokenOwner,                          // the token owner can claim for free if no one bids
            0,                                   // no bid has been placed (latestBid = 0)
            startingPrice,                       // minimum bid (can be customised per auction)
            uint32(block.timestamp + 24 hours),  // auction ends 24 hours from now
            tokenERCStandard,                    // ERC721 or ERC1155
            tokenAmount,                         // the number of tokens with that ID (for ERC1155)
            false                                // the auction is not settled
        );

        emit AuctionInitialised(nextAuctionId);

        nextAuctionId++;
    }

    /// @dev Extends the end time of an auction if we are within the grace period.
    function _maybeExtendTime (uint64 auctionId, Auction storage auction) internal {
        uint64 gracePeriodStart = auction.endTimestamp - BIDDING_GRACE_PERIOD;
        uint64 _now = uint64(block.timestamp);
        if (_now > gracePeriodStart) {
            auction.endTimestamp = uint32(_now + BIDDING_GRACE_PERIOD);

            emit AuctionExtended(auctionId, auction.endTimestamp);
        }
    }

    /// @dev Whether an auction has an existing bid
    function _hasBid (Auction memory auction) internal pure returns (bool) {
        return auction.latestBid > 0;
    }

    /// @dev Calculates the minimum price for the next bid
    function _currentBidPrice (Auction memory auction) internal pure returns (uint128) {
        if (! _hasBid(auction)) {
            return auction.startingPrice;
        }

        uint128 percentageIncreasePrice = auction.latestBid * (100 + BID_PERCENTAGE_INCREASE) / 100;
        return percentageIncreasePrice - auction.latestBid < auction.startingPrice
            ? auction.latestBid + auction.startingPrice
            : percentageIncreasePrice;
    }

    /// @dev Transform a bytes string into a uint64. If no string provided, return 0
    function toUint64(bytes memory _bytes) internal pure returns (uint64) {
        if (_bytes.length == 0) return 0;

        require(_bytes.length <= 8, "toUint64_outOfBounds");
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), 0))
        }

        return tempUint;
    }
}
