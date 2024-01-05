// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.6.0;
import "./Ownable.sol";
import "./IERC20.sol";
import "./IERC1155.sol";
import "./SafeMath.sol";

contract NFTAuctionSale is Ownable {
    using SafeMath for uint256;

    event NewAuctionItemCreated(uint256 auctionId);
    event EmergencyStarted();
    event EmergencyStopped();
    event BidPlaced(
        uint256 auctionId,
        address paymentTokenAddress,
        uint256 bidId,
        address addr,
        uint256 bidPrice,
        uint256 timestamp,
        address transaction
    );
    event BidReplaced(
        uint256 auctionId,
        address paymentTokenAddress,
        uint256 bidId,
        address addr,
        uint256 bidPrice,
        uint256 timestamp,
        address transaction
    );

    event RewardClaimed(address addr, uint256 auctionId, uint256 tokenCount);
    event BidIncreased(
        uint256 auctionId,
        address paymentTokenAddress,
        uint256 bidId,
        address addr,
        uint256 bidPrice,
        uint256 timestamp,
        address transaction
    );

    struct AuctionProgress {
        uint256 currentPrice;
        address bidder;
    }

    struct AuctionInfo {
        uint256 startTime;
        uint256 endTime;
        uint256 totalSupply;
        uint256 startPrice;
        address paymentTokenAddress; // ERC20
        address auctionItemAddress; // ERC1155
        uint256 auctionItemTokenId;
    }

    address public salesPerson = address(0);

    bool private emergencyStop = false;

    mapping(uint256 => AuctionInfo) private auctions;
    mapping(uint256 => mapping(uint256 => AuctionProgress)) private bids;
    mapping(uint256 => mapping(address => uint256)) private currentBids;

    uint256 public totalAuctionCount = 0;

    constructor() public {}

    modifier onlySalesPerson {
        require(
            _msgSender() == salesPerson,
            "Only salesPerson can call this function"
        );
        _;
    }

    function setSalesPerson(address _salesPerson) external onlyOwner {
        salesPerson = _salesPerson;
    }

    function max(uint256 a, uint256 b) private pure returns (uint256) {
        return a > b ? a : b;
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

    function getBatchAuctions(uint256 fromId)
        external
        view
        returns (AuctionInfo[] memory)
    {
        require(fromId <= totalAuctionCount, "Invalid auction id");
        AuctionInfo[] memory currentAuctions =
            new AuctionInfo[](totalAuctionCount - fromId + 1);
        for (uint256 i = fromId; i <= totalAuctionCount; i++) {
            AuctionInfo storage auction = auctions[i];
            currentAuctions[i - fromId] = auction;
        }
        return currentAuctions;
    }

    function getBids(uint256 auctionId)
        external
        view
        returns (AuctionProgress[] memory)
    {
        require(auctionId <= totalAuctionCount, "Invalid auction id");
        AuctionInfo storage auction = auctions[auctionId];
        AuctionProgress[] memory lBids =
            new AuctionProgress[](auction.totalSupply);
        mapping(uint256 => AuctionProgress) storage auctionBids =
            bids[auctionId];
        for (uint256 i = 0; i < auction.totalSupply; i++) {
            AuctionProgress storage lBid = auctionBids[i];
            lBids[i] = lBid;
        }
        return lBids;
    }

    /// @notice Get max bid price in the specified auction
    /// @param auctionId Auction Id
    /// @return the max bid price
    function getMaxPrice(uint256 auctionId) public view returns (uint256) {
        require(auctionId <= totalAuctionCount, "Invalid auction id");
        AuctionInfo storage auction = auctions[auctionId];
        mapping(uint256 => AuctionProgress) storage auctionBids =
            bids[auctionId];

        uint256 maxPrice = auctionBids[0].currentPrice;
        for (uint256 i = 1; i < auction.totalSupply; i++) {
            maxPrice = max(maxPrice, auctionBids[i].currentPrice);
        }

        return maxPrice;
    }

    /// @notice Get min bid price in the specified auction
    /// @param auctionId Auction Id
    /// @return the min bid price
    function getMinPrice(uint256 auctionId) public view returns (uint256) {
        require(auctionId <= totalAuctionCount, "Invalid auction id");
        AuctionInfo storage auction = auctions[auctionId];
        mapping(uint256 => AuctionProgress) storage auctionBids =
            bids[auctionId];

        uint256 minPrice = auctionBids[0].currentPrice;
        for (uint256 i = 1; i < auction.totalSupply; i++) {
            minPrice = min(minPrice, auctionBids[i].currentPrice);
        }

        return minPrice;
    }

    /// @notice Transfers ERC20 tokens holding in contract to the contract owner
    /// @param tokenAddr ERC20 token address
    function transferERC20(address tokenAddr) external onlySalesPerson {
        IERC20 erc20 = IERC20(tokenAddr);
        erc20.transfer(_msgSender(), erc20.balanceOf(address(this)));
    }

    /// @notice Transfers ETH holding in contract to the contract owner
    function transferETH() external onlySalesPerson {
        _msgSender().transfer(address(this).balance);
    }

    /// @notice Create auction with specific parameters
    /// @param paymentTokenAddress ERC20 token address the bidders will pay
    /// @param paymentTokenAddress ERC1155 token address for the auction
    /// @param auctionItemTokenId Token ID of NFT
    /// @param totalSupply ERC20 token address
    /// @param startPrice Bid starting price
    /// @param startTime Auction starting time
    /// @param endTime Auction ending time
    function createAuction(
        address paymentTokenAddress,
        address auctionItemAddress,
        uint256 auctionItemTokenId,
        uint256 startPrice,
        uint256 totalSupply,
        uint256 startTime,
        uint256 endTime
    ) external onlyOwner {
        require(
            salesPerson != address(0),
            "Salesperson address should be valid"
        );
        require(emergencyStop == false, "Emergency stopped");
        require(totalSupply > 0, "Total supply should be greater than 0");
        IERC1155 auctionToken = IERC1155(auctionItemAddress);

        // check if the input address is ERC1155
        require(
            auctionToken.supportsInterface(0xd9b67a26),
            "Auction token is not ERC1155"
        );

        // check NFT balance
        require(
            auctionToken.balanceOf(salesPerson, auctionItemTokenId) >=
                totalSupply,
            "NFT balance not sufficient"
        );

        // check allowance
        require(
            auctionToken.isApprovedForAll(salesPerson, address(this)),
            "Auction token from sales person has no allowance for this contract"
        );

        // Init auction struct

        // increment auction index and push
        totalAuctionCount = totalAuctionCount.add(1);
        auctions[totalAuctionCount] = AuctionInfo(
            startTime,
            endTime,
            totalSupply,
            startPrice,
            paymentTokenAddress,
            auctionItemAddress,
            auctionItemTokenId
        );

        // emit event
        emit NewAuctionItemCreated(totalAuctionCount);
    }

    /// @notice Claim auction reward tokens to the caller
    /// @param auctionId Auction Id
    function claimReward(uint256 auctionId) external {
        require(emergencyStop == false, "Emergency stopped");
        require(auctionId <= totalAuctionCount, "Auction id is invalid");

        require(
            auctions[auctionId].endTime <= block.timestamp,
            "Auction is not ended yet"
        );

        mapping(address => uint256) storage auctionCurrentBids =
            currentBids[auctionId];
        uint256 totalWon = auctionCurrentBids[_msgSender()];

        require(totalWon > 0, "Nothing to claim");

        auctionCurrentBids[_msgSender()] = 0;

        IERC1155(auctions[auctionId].auctionItemAddress).safeTransferFrom(
            salesPerson,
            _msgSender(),
            auctions[auctionId].auctionItemTokenId,
            totalWon,
            ""
        );

        emit RewardClaimed(_msgSender(), auctionId, totalWon);
    }

    /// @notice Increase the caller's bid price
    /// @param auctionId Auction Id
    function increaseMyBidETH(uint256 auctionId) external payable {
        require(emergencyStop == false, "Emergency stopped");
        require(auctionId <= totalAuctionCount, "Auction id is invalid");
        require(msg.value > 0, "Wrong amount");
        require(
            block.timestamp < auctions[auctionId].endTime,
            "Auction is ended"
        );

        AuctionInfo storage auction = auctions[auctionId];

        require(
            auction.paymentTokenAddress == address(0),
            "Cannot use ETH in this auction"
        );

        uint256 count = currentBids[auctionId][_msgSender()];
        require(count > 0, "Not in current bids");

        mapping(uint256 => AuctionProgress) storage auctionBids =
            bids[auctionId];

        // Iterate currentBids and increment currentPrice
        for (uint256 i = 0; i < auction.totalSupply; i++) {
            AuctionProgress storage progress = auctionBids[i];
            if (progress.bidder == _msgSender()) {
                progress.currentPrice = progress.currentPrice.add(msg.value);
                emit BidIncreased(
                    auctionId,
                    auction.paymentTokenAddress,
                    i,
                    _msgSender(),
                    progress.currentPrice,
                    block.timestamp,
                    tx.origin
                );
            }
        }
    }

    /// @notice Place bid on auction with the specified price with ETH
    /// @param auctionId Auction Id
    function makeBidETH(uint256 auctionId)
        external
        payable
        isBidAvailable(auctionId)
    {
        uint256 minIndex = 0;
        uint256 minPrice = getMinPrice(auctionId);

        AuctionInfo storage auction = auctions[auctionId];
        require(
            auction.paymentTokenAddress == address(0),
            "Cannot use ETH in this auction"
        );
        require(
            msg.value >= auction.startPrice && msg.value > minPrice,
            "Cannot place bid at low price"
        );

        mapping(address => uint256) storage auctionCurrentBids =
            currentBids[auctionId];
        require(
            auctionCurrentBids[_msgSender()] < 1,
            "Max bid per wallet exceeded"
        );

        mapping(uint256 => AuctionProgress) storage auctionBids =
            bids[auctionId];

        for (uint256 i = 0; i < auction.totalSupply; i++) {
            // Just place the bid if remaining
            if (auctionBids[i].currentPrice == 0) {
                minIndex = i;
                break;
            } else if (auctionBids[i].currentPrice == minPrice) {
                // Get last minimum price bidder
                minIndex = i;
            }
        }

        if (auctionBids[minIndex].currentPrice != 0) {
            // return previous bidders tokens
            (bool sent, bytes memory data) =
                address(auctionBids[minIndex].bidder).call{
                    value: auctionBids[minIndex].currentPrice
                }("");
            require(sent, "Failed to send Ether");

            auctionCurrentBids[auctionBids[minIndex].bidder]--;

            emit BidReplaced(
                auctionId,
                auction.paymentTokenAddress,
                minIndex,
                auctionBids[minIndex].bidder,
                auctionBids[minIndex].currentPrice,
                block.timestamp,
                tx.origin
            );
        }

        auctionBids[minIndex].currentPrice = msg.value;
        auctionBids[minIndex].bidder = _msgSender();

        auctionCurrentBids[_msgSender()] = auctionCurrentBids[_msgSender()].add(
            1
        );

        emit BidPlaced(
            auctionId,
            auction.paymentTokenAddress,
            minIndex,
            _msgSender(),
            msg.value,
            block.timestamp,
            tx.origin
        );
    }

    /// @notice Increase the caller's bid price
    /// @param auctionId Auction Id
    /// @param increaseAmount The incrementing price than the original bid
    function increaseMyBid(uint256 auctionId, uint256 increaseAmount) external {
        require(emergencyStop == false, "Emergency stopped");
        require(auctionId <= totalAuctionCount, "Auction id is invalid");
        require(increaseAmount > 0, "Wrong amount");
        require(
            block.timestamp < auctions[auctionId].endTime,
            "Auction is ended"
        );

        AuctionInfo storage auction = auctions[auctionId];

        require(auction.paymentTokenAddress != address(0), "Wrong function");

        uint256 count = currentBids[auctionId][_msgSender()];
        require(count > 0, "Not in current bids");

        IERC20(auction.paymentTokenAddress).transferFrom(
            _msgSender(),
            address(this),
            increaseAmount * count
        );

        mapping(uint256 => AuctionProgress) storage auctionBids =
            bids[auctionId];

        // Iterate currentBids and increment currentPrice
        for (uint256 i = 0; i < auction.totalSupply; i++) {
            AuctionProgress storage progress = auctionBids[i];
            if (progress.bidder == _msgSender()) {
                progress.currentPrice = progress.currentPrice.add(
                    increaseAmount
                );
                emit BidIncreased(
                    auctionId,
                    auction.paymentTokenAddress,
                    i,
                    _msgSender(),
                    progress.currentPrice,
                    block.timestamp,
                    tx.origin
                );
            }
        }
    }

    /// @notice Place bid on auction with the specified price
    /// @param auctionId Auction Id
    /// @param bidPrice ERC20 token amount
    function makeBid(uint256 auctionId, uint256 bidPrice)
        external
        isBidAvailable(auctionId)
    {
        uint256 minIndex = 0;
        uint256 minPrice = getMinPrice(auctionId);

        AuctionInfo storage auction = auctions[auctionId];
        require(auction.paymentTokenAddress != address(0), "Wrong function");
        IERC20 paymentToken = IERC20(auction.paymentTokenAddress);
        require(
            bidPrice >= auction.startPrice && bidPrice > minPrice,
            "Cannot place bid at low price"
        );

        uint256 allowance = paymentToken.allowance(_msgSender(), address(this));
        require(allowance >= bidPrice, "Check the token allowance");

        mapping(address => uint256) storage auctionCurrentBids =
            currentBids[auctionId];
        require(
            auctionCurrentBids[_msgSender()] < 1,
            "Max bid per wallet exceeded"
        );

        mapping(uint256 => AuctionProgress) storage auctionBids =
            bids[auctionId];

        for (uint256 i = 0; i < auction.totalSupply; i++) {
            // Just place the bid if remaining
            if (auctionBids[i].currentPrice == 0) {
                minIndex = i;
                break;
            } else if (auctionBids[i].currentPrice == minPrice) {
                // Get last minimum price bidder
                minIndex = i;
            }
        }

        // Replace current minIndex bidder with the msg.sender
        paymentToken.transferFrom(_msgSender(), address(this), bidPrice);

        if (auctionBids[minIndex].currentPrice != 0) {
            // return previous bidders tokens
            paymentToken.transferFrom(
                address(this),
                auctionBids[minIndex].bidder,
                auctionBids[minIndex].currentPrice
            );
            auctionCurrentBids[auctionBids[minIndex].bidder]--;

            emit BidReplaced(
                auctionId,
                auction.paymentTokenAddress,
                minIndex,
                auctionBids[minIndex].bidder,
                auctionBids[minIndex].currentPrice,
                block.timestamp,
                tx.origin
            );
        }

        auctionBids[minIndex].currentPrice = bidPrice;
        auctionBids[minIndex].bidder = _msgSender();

        auctionCurrentBids[_msgSender()] = auctionCurrentBids[_msgSender()].add(
            1
        );

        emit BidPlaced(
            auctionId,
            auction.paymentTokenAddress,
            minIndex,
            _msgSender(),
            bidPrice,
            block.timestamp,
            tx.origin
        );
    }

    modifier isBidAvailable(uint256 auctionId) {
        require(
            !emergencyStop &&
                auctionId <= totalAuctionCount &&
                auctions[auctionId].startTime <= block.timestamp &&
                auctions[auctionId].endTime > block.timestamp
        );
        _;
    }

    /// @notice Check the auction is finished
    /// @param auctionId Auction Id
    /// @return bool true if finished, otherwise false
    function isAuctionFinished(uint256 auctionId) external view returns (bool) {
        require(auctionId <= totalAuctionCount, "Invalid auction id");
        return (emergencyStop || auctions[auctionId].endTime < block.timestamp);
    }

    /// @notice Get remaining time for the auction
    /// @param auctionId Auction Id
    /// @return uint the remaining time for the auction
    function getTimeRemaining(uint256 auctionId)
        external
        view
        returns (uint256)
    {
        require(auctionId <= totalAuctionCount, "Invalid auction id");
        return auctions[auctionId].endTime - block.timestamp;
    }

    /// @notice Start emergency, only owner action
    function setEmergencyStart() external onlyOwner {
        emergencyStop = true;
        emit EmergencyStarted();
    }

    /// @notice Stop emergency, only owner action
    function setEmergencyStop() external onlyOwner {
        emergencyStop = false;
        emit EmergencyStopped();
    }

    /// @notice Change start time for auction
    /// @param auctionId Auction Id
    /// @param startTime new start time
    function setStartTimeForAuction(uint256 auctionId, uint256 startTime)
        external
        onlyOwner
    {
        require(auctionId <= totalAuctionCount, "Invalid auction id");
        auctions[auctionId].startTime = startTime;
    }

    /// @notice Change end time for auction
    /// @param auctionId Auction Id
    /// @param endTime new end time
    function setEndTimeForAuction(uint256 auctionId, uint256 endTime)
        external
        onlyOwner
    {
        require(auctionId <= totalAuctionCount, "Invalid auction id");
        auctions[auctionId].endTime = endTime;
    }

    /// @notice Change total supply for auction
    /// @param auctionId Auction Id
    /// @param totalSupply new Total supply
    function setTotalSupplyForAuction(uint256 auctionId, uint256 totalSupply)
        external
        onlyOwner
    {
        require(totalSupply > 0, "Total supply should be greater than 0");
        require(auctionId <= totalAuctionCount, "Invalid auction id");
        auctions[auctionId].totalSupply = totalSupply;
    }

    /// @notice Change start price for auction
    /// @param auctionId Auction Id
    /// @param startPrice new Total supply
    function setStartPriceForAuction(uint256 auctionId, uint256 startPrice)
        external
        onlyOwner
    {
        require(auctionId <= totalAuctionCount, "Invalid auction id");
        auctions[auctionId].startPrice = startPrice;
    }

    /// @notice Change ERC20 token address for auction
    /// @param auctionId Auction Id
    /// @param paymentTokenAddress new ERC20 token address
    function setPaymentTokenAddressForAuction(
        uint256 auctionId,
        address paymentTokenAddress
    ) external onlyOwner {
        require(auctionId <= totalAuctionCount, "Invalid auction id");
        auctions[auctionId].paymentTokenAddress = paymentTokenAddress;
    }

    /// @notice Change auction item address for auction
    /// @param auctionId Auction Id
    /// @param auctionItemAddress new Auctioned item address
    function setAuctionItemAddress(
        uint256 auctionId,
        address auctionItemAddress
    ) external onlyOwner {
        require(auctionId <= totalAuctionCount, "Invalid auction id");
        auctions[auctionId].auctionItemAddress = auctionItemAddress;
    }

    /// @notice Change auction item token id
    /// @param auctionId Auction Id
    /// @param auctionItemTokenId new token id
    function setAuctionItemTokenId(
        uint256 auctionId,
        uint256 auctionItemTokenId
    ) external onlyOwner {
        require(auctionId <= totalAuctionCount, "Invalid auction id");
        auctions[auctionId].auctionItemTokenId = auctionItemTokenId;
    }
}
