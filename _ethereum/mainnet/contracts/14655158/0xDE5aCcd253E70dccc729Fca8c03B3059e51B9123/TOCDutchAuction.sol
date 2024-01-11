//solhint-disable not-rely-on-time
//solhint-disable avoid-low-level-calls

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./ReentrancyGuard.sol";
import "./TOCBaseSale.sol";
import "./DecimalMath.sol";

contract TOCDutchAuction is TOCBaseSale, ReentrancyGuard {
    using DecimalMath for uint256;

    /// @notice event emitted when seller put tokenIds on auction
    event AuctionCreated(
        uint256 indexed auctionId,
        address indexed seller,
        uint256 startTime,
        uint256 tokenId
    );

    /// @notice structure for each auction information
    struct AuctionInfo {
        /// @notice seller address
        address seller;
        /// @notice auction start time
        uint256 startTime;
        /// @notice tokenId to put on auction
        uint256 tokenId;
    }

    /// @notice auctionId => auction info structure
    mapping(uint256 => AuctionInfo) public auctionInfos;

    constructor(address toc)
        TOCBaseSale(toc) //solhint-disable-next-line
    {}

    /**
     * @dev put tokenId on auction
     * @param tokenId tokenId
     * @param startTime auction start time
     */
    function createAuction(uint256 tokenId, uint256 startTime) external {
        require(tokenId > 0, "Auction: INVALID_TOKEN");
        require(startTime > block.timestamp, "Auction: PAST_TIME");

        tocNFT.safeTransferFrom(msg.sender, address(this), tokenId);
        lastSaleId += 1;
        auctionInfos[lastSaleId] = AuctionInfo(msg.sender, startTime, tokenId);

        emit AuctionCreated(lastSaleId, msg.sender, startTime, tokenId);
    }

    /**
     * @dev cancel auction
     * @param auctionId auction id to cancel
     */
    function cancelAuction(uint256 auctionId) external {
        AuctionInfo storage auction = auctionInfos[auctionId];
        require(auction.seller == msg.sender || msg.sender == address(this), "Auction: NOT_SELLER");

        tocNFT.safeTransferFrom(address(this), auction.seller, auction.tokenId);

        emit SaleCancelled(auctionId);
        delete auctionInfos[auctionId];
    }

    /**
     * @dev end auction and give TOC to top bidder
     * @param auctionId auction auction id
     */
    function completeAuction(uint256 auctionId) external payable nonReentrant {
        AuctionInfo storage auction = auctionInfos[auctionId];
        if (auction.startTime + 180 * 60 + 7 * 86400 < block.timestamp) {
            this.cancelAuction(auctionId);
            return;
        }
        require(checkIfPriceMatches(auction.startTime, msg.value), "Auction: INCORRECT_BID_PRICE");

        _completeAuction(auction.seller, msg.sender, auctionId, auction.tokenId, msg.value);
    }

    function checkIfPriceMatches(uint256 startTime, uint256 price)
        internal
        view
        returns (bool matches)
    {
        uint256 diff = block.timestamp - startTime;
        if (diff / 60 <= 180) {
            // until price reaches minimum 0.1 ETH
            matches = price / 10**16 == (100 - (5 * diff) / 600);
        } else if (diff <= 180 * 60 + 7 * 86400) {
            matches = price == 10**17;
        }
    }

    function _completeAuction(
        address seller,
        address buyer,
        uint256 auctionId,
        uint256 tokenId,
        uint256 price
    ) internal {
        uint256 fee = price.decimalMul(treasury.fee);
        (bool success1, ) = seller.call{value: price - fee}("");
        require(success1, "Auction: TRANSFER_FAILED");
        if (fee > 0) {
            (bool success2, ) = treasury.treasury.call{value: fee}("");
            require(success2, "Auction: FEE_TRANSFER_FAILED");
        }

        tocNFT.safeTransferFrom(address(this), buyer, tokenId);

        emit Purchased(seller, buyer, auctionId, price);
        delete auctionInfos[auctionId];
    }
}
