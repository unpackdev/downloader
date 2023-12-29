// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

//                            _.-^-._    .--.
//                         .-'   _   '-. |__|
//                        /     |_|     \|  |
//                       /               \  |
//                      /|     _____     |\ |
//                       |    |==|==|    |  |
//   |---|---|---|---|---|    |--|--|    |  |
//   |---|---|---|---|---|    |==|==|    |  |
//  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
//  _______  Harvest.art v3 (Auctions) _________

import "./IERC721.sol";
import "./IERC1155.sol";
import "./Ownable.sol";
import "./IBidTicket.sol";

enum Status {
    Active,
    Claimed,
    Refunded,
    Abandoned,
    Withdrawn
}

struct Auction {
    uint8 auctionType;
    address tokenAddress;
    uint64 endTime;
    uint8 tokenCount;
    Status status;
    address highestBidder;
    uint256 highestBid;
    mapping(uint256 => uint256) tokenIds;
    mapping(uint256 => uint256) amounts;
}

contract Auctions is Ownable {
    uint8 private constant AUCTION_TYPE_ERC721 = 0;
    uint8 private constant AUCTION_TYPE_ERC1155 = 1;

    IBidTicket public bidTicket;

    address public theBarn;
    uint256 public bidTicketTokenId = 1;
    uint256 public bidTicketCostStart = 5;
    uint256 public bidTicketCostBid = 1;
    uint256 public maxTokens = 10;
    uint256 public nextAuctionId = 1;
    uint256 public minStartingBid = 0.05 ether;
    uint256 public minBidIncrement = 0.01 ether;
    uint256 public auctionDuration = 7 days;
    uint256 public settlementDuration = 7 days;

    uint256 public constant ABANDONMENT_FEE_PERCENT = 20;

    mapping(uint256 => Auction) public auctions;
    mapping(address => mapping(uint256 => bool)) public auctionTokensERC721;
    mapping(address => mapping(uint256 => uint256)) public auctionTokensERC1155;

    error AuctionAbandoned();
    error AuctionActive();
    error AuctionClaimed();
    error AuctionEnded();
    error AuctionIsApproved();
    error AuctionNotClaimed();
    error AuctionNotEnded();
    error AuctionRefunded();
    error AuctionWithdrawn();
    error BidTooLow();
    error InvalidLengthOfAmounts();
    error InvalidLengthOfTokenIds();
    error MaxTokensPerTxReached();
    error NotEnoughTokensInSupply();
    error NotHighestBidder();
    error SettlementPeriodNotExpired();
    error SettlementPeriodEnded();
    error StartPriceTooLow();
    error TokenAlreadyInAuction();
    error TokenNotOwned();
    error TransferFailed();

    event Abandoned(uint256 indexed auctionId, address indexed bidder, uint256 indexed fee);
    event AuctionStarted(address indexed bidder, address indexed tokenAddress, uint256[] indexed tokenIds);
    event Claimed(uint256 indexed auctionId, address indexed winner);
    event NewBid(uint256 indexed auctionId, address indexed bidder, uint256 indexed value);
    event Refunded(uint256 indexed auctionId, address indexed bidder, uint256 indexed value);
    event Withdrawn(uint256 indexed auctionId, address indexed bidder, uint256 indexed value);

    constructor(address theBarn_, address bidTicket_) {
        _initializeOwner(msg.sender);
        theBarn = theBarn_;
        bidTicket = IBidTicket(bidTicket_);
    }

    /**
     *
     * startAuction - Starts an auction for a given token
     *
     * @param tokenAddress - The address of the token contract
     * @param tokenIds - The token ids to auction
     *
     */

    function startAuctionERC721(address tokenAddress, uint256[] calldata tokenIds) external payable {
        if (msg.value < minStartingBid) {
            revert StartPriceTooLow();
        }

        bidTicket.burn(msg.sender, bidTicketTokenId, bidTicketCostStart);

        _validateAuctionTokensERC721(tokenAddress, tokenIds);

        Auction storage auction = auctions[nextAuctionId];

        auction.auctionType = AUCTION_TYPE_ERC721;
        auction.tokenAddress = tokenAddress;
        auction.endTime = uint64(block.timestamp + auctionDuration);
        auction.highestBidder = msg.sender;
        auction.highestBid = msg.value;
        auction.tokenCount = uint8(tokenIds.length);

        mapping(uint256 => uint256) storage tokenMap = auction.tokenIds;

        for (uint256 i; i < tokenIds.length;) {
            tokenMap[i] = tokenIds[i];

            unchecked {
                ++i;
            }
        }

        unchecked {
            ++nextAuctionId;
        }

        emit AuctionStarted(msg.sender, tokenAddress, tokenIds);
    }

    /**
     *
     * startAuction - Starts an auction for a given token
     *
     * @param tokenAddress - The address of the token contract
     * @param tokenIds - The token ids to auction
     * @param amounts - The amounts of each token to auction
     *
     */

    function startAuctionERC1155(address tokenAddress, uint256[] calldata tokenIds, uint256[] calldata amounts)
        external
        payable
    {
        if (msg.value < minStartingBid) {
            revert StartPriceTooLow();
        }

        bidTicket.burn(msg.sender, bidTicketTokenId, bidTicketCostStart);

        _validateAuctionTokensERC1155(tokenAddress, tokenIds, amounts);

        Auction storage auction = auctions[nextAuctionId];

        auction.auctionType = AUCTION_TYPE_ERC1155;
        auction.tokenAddress = tokenAddress;
        auction.endTime = uint64(block.timestamp + auctionDuration);
        auction.highestBidder = msg.sender;
        auction.highestBid = msg.value;
        auction.tokenCount = uint8(tokenIds.length);

        mapping(uint256 => uint256) storage tokenMap = auction.tokenIds;
        mapping(uint256 => uint256) storage amountMap = auction.amounts;

        for (uint256 i; i < tokenIds.length;) {
            tokenMap[i] = tokenIds[i];
            amountMap[i] = amounts[i];

            unchecked {
                ++i;
            }
        }

        unchecked {
            ++nextAuctionId;
        }

        emit AuctionStarted(msg.sender, tokenAddress, tokenIds);
    }

    /**
     * bid - Places a bid on an auction
     *
     * @param auctionId - The id of the auction to bid on
     *
     */

    function bid(uint256 auctionId) external payable {
        Auction storage auction = auctions[auctionId];

        if (block.timestamp > auction.endTime) {
            revert AuctionEnded();
        }

        if (block.timestamp >= auction.endTime - 1 hours) {
            auction.endTime += 1 hours;
        }

        if (msg.value < auction.highestBid + minBidIncrement) {
            revert BidTooLow();
        }

        address prevHighestBidder = auction.highestBidder;
        uint256 prevHighestBid = auction.highestBid;

        auction.highestBidder = msg.sender;
        auction.highestBid = msg.value;

        bidTicket.burn(msg.sender, bidTicketTokenId, bidTicketCostBid);

        if (prevHighestBidder != address(0)) {
            (bool success,) = payable(prevHighestBidder).call{value: prevHighestBid}("");
            if (!success) revert TransferFailed();
        }

        emit NewBid(auctionId, msg.sender, msg.value);
    }

    /**
     * claim - Claims the tokens from an auction
     *
     * @param auctionId - The id of the auction to claim
     *
     */

    function claim(uint256 auctionId) external {
        Auction storage auction = auctions[auctionId];

        if (block.timestamp < auction.endTime) {
            revert AuctionNotEnded();
        }

        if (msg.sender != auction.highestBidder) {
            revert NotHighestBidder();
        }

        if (auction.status != Status.Active) {
            if (auction.status == Status.Refunded) {
                revert AuctionRefunded();
            } else if (auction.status == Status.Claimed) {
                revert AuctionClaimed();
            } else if (auction.status == Status.Abandoned) {
                revert AuctionAbandoned();
            }
        }

        auction.status = Status.Claimed;

        if (auction.auctionType == AUCTION_TYPE_ERC721) {
            _transferERC721s(auction);
        } else {
            _transferERC1155s(auction);
        }

        emit Claimed(auctionId, msg.sender);
    }

    /**
     * refund - Refunds are available during the settlement period if The Barn has not yet approved the collection
     *
     * @param auctionId - The id of the auction to refund
     *
     */
    function refund(uint256 auctionId) external {
        Auction storage auction = auctions[auctionId];
        uint256 highestBid = auction.highestBid;
        uint256 endTime = auction.endTime;

        if (block.timestamp < endTime) {
            revert AuctionActive();
        }

        if (block.timestamp > endTime + settlementDuration) {
            revert SettlementPeriodEnded();
        }

        if (msg.sender != auction.highestBidder) {
            revert NotHighestBidder();
        }

        if (auction.status != Status.Active) {
            if (auction.status == Status.Refunded) {
                revert AuctionRefunded();
            } else if (auction.status == Status.Claimed) {
                revert AuctionClaimed();
            } else if (auction.status == Status.Withdrawn) {
                revert AuctionWithdrawn();
            }
        }

        if (auction.auctionType == AUCTION_TYPE_ERC721) {
            _checkAndResetERC721s(auction);
        } else {
            _checkAndResetERC1155s(auction);
        }

        auction.status = Status.Refunded;

        (bool success,) = payable(msg.sender).call{value: highestBid}("");
        if (!success) revert TransferFailed();

        emit Refunded(auctionId, msg.sender, highestBid);
    }

    /**
     *
     * abandon - Mark unclaimed auctions as abandoned after the settlement period
     *
     * @param auctionId - The id of the auction to abandon
     *
     */
    function abandon(uint256 auctionId) external onlyOwner {
        Auction storage auction = auctions[auctionId];
        address highestBidder = auction.highestBidder;
        uint256 highestBid = auction.highestBid;

        if (block.timestamp < auction.endTime + settlementDuration) {
            revert SettlementPeriodNotExpired();
        }

        if (auction.status != Status.Active) {
            if (auction.status == Status.Abandoned) {
                revert AuctionAbandoned();
            } else if (auction.status == Status.Refunded) {
                revert AuctionRefunded();
            } else if (auction.status == Status.Claimed) {
                revert AuctionClaimed();
            }
        }

        auction.status = Status.Abandoned;

        if (auction.auctionType == AUCTION_TYPE_ERC721) {
            _resetERC721s(auction);
        } else {
            _resetERC1155s(auction);
        }

        uint256 fee = highestBid * ABANDONMENT_FEE_PERCENT / 100;

        (bool success,) = payable(highestBidder).call{value: highestBid - fee}("");
        if (!success) revert TransferFailed();

        (success,) = payable(msg.sender).call{value: fee}("");
        if (!success) revert TransferFailed();

        emit Abandoned(auctionId, highestBidder, fee);
    }

    /**
     * withdraw - Withdraws the highest bid from claimed auctions
     *
     * @param auctionIds - The ids of the auctions to withdraw from
     *
     * @notice - Auctions can only be withdrawn after the settlement period has ended.
     *
     */

    function withdraw(uint256[] calldata auctionIds) external onlyOwner {
        uint256 totalAmount;

        for (uint256 i; i < auctionIds.length;) {
            Auction storage auction = auctions[auctionIds[i]];

            if (auction.status != Status.Claimed) {
                revert AuctionNotClaimed();
            }

            totalAmount += auction.highestBid;
            auction.status = Status.Withdrawn;

            unchecked {
                ++i;
            }
        }

        (bool success,) = payable(msg.sender).call{value: totalAmount}("");
        if (!success) revert TransferFailed();
    }

    /**
     *
     * Getters & Setters
     *
     */

    function getAuctionTokens(uint256 auctionId) external view returns (uint256[] memory, uint256[] memory) {
        Auction storage auction = auctions[auctionId];

        uint256[] memory tokenIds = new uint256[](auction.tokenCount);
        uint256[] memory amounts = new uint256[](auction.tokenCount);

        uint256 tokenCount = auction.tokenCount;

        for (uint256 i; i < tokenCount;) {
            tokenIds[i] = auction.tokenIds[i];
            if (auction.auctionType == AUCTION_TYPE_ERC721) {
                amounts[i] = 1;
            } else {
                amounts[i] = auction.amounts[i];
            }

            unchecked {
                ++i;
            }
        }

        return (tokenIds, amounts);
    }

    function setBarnAddress(address theBarn_) external onlyOwner {
        theBarn = theBarn_;
    }

    function setBidTicketAddress(address bidTicket_) external onlyOwner {
        bidTicket = IBidTicket(bidTicket_);
    }

    function setBidTicketTokenId(uint256 bidTicketTokenId_) external onlyOwner {
        bidTicketTokenId = bidTicketTokenId_;
    }

    function setMaxTokens(uint256 maxTokens_) external onlyOwner {
        maxTokens = maxTokens_;
    }

    function setMinStartingBid(uint256 minStartingBid_) external onlyOwner {
        minStartingBid = minStartingBid_;
    }

    function setMinBidIncrement(uint256 minBidIncrement_) external onlyOwner {
        minBidIncrement = minBidIncrement_;
    }

    function setAuctionDuration(uint256 auctionDuration_) external onlyOwner {
        auctionDuration = auctionDuration_;
    }

    function setSettlementDuration(uint256 settlementDuration_) external onlyOwner {
        settlementDuration = settlementDuration_;
    }

    /**
     *
     * Internal Functions
     *
     */

    function _validateAuctionTokensERC721(address tokenAddress, uint256[] calldata tokenIds) internal {
        if (tokenIds.length == 0) {
            revert InvalidLengthOfTokenIds();
        }

        IERC721 erc721Contract = IERC721(tokenAddress);

        if (tokenIds.length > maxTokens) {
            revert MaxTokensPerTxReached();
        }

        mapping(uint256 => bool) storage auctionTokens = auctionTokensERC721[tokenAddress];

        for (uint256 i; i < tokenIds.length;) {
            uint256 tokenId = tokenIds[i];

            if (auctionTokens[tokenId]) {
                revert TokenAlreadyInAuction();
            }

            auctionTokens[tokenId] = true;

            if (erc721Contract.ownerOf(tokenId) != theBarn) {
                revert TokenNotOwned();
            }

            unchecked {
                ++i;
            }
        }
    }

    function _validateAuctionTokensERC1155(
        address tokenAddress,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) internal {
        if (tokenIds.length == 0) {
            revert InvalidLengthOfTokenIds();
        }

        if (tokenIds.length != amounts.length) {
            revert InvalidLengthOfAmounts();
        }

        IERC1155 erc1155Contract = IERC1155(tokenAddress);
        uint256 totalTokens;
        uint256 totalNeeded;
        uint256 balance;
        uint256 tokenId;
        uint256 amount;

        mapping(uint256 => uint256) storage auctionTokens = auctionTokensERC1155[tokenAddress];

        for (uint256 i; i < tokenIds.length;) {
            tokenId = tokenIds[i];
            amount = amounts[i];

            totalTokens += amount;
            totalNeeded = auctionTokens[tokenId] + amount;
            balance = erc1155Contract.balanceOf(theBarn, tokenId);

            if (totalNeeded > balance) {
                revert NotEnoughTokensInSupply();
            }

            unchecked {
                auctionTokens[tokenId] += amount;
                ++i;
            }
        }

        if (totalTokens > maxTokens) {
            revert MaxTokensPerTxReached();
        }
    }

    function _transferERC721s(Auction storage auction) internal {
        address tokenAddress = auction.tokenAddress;
        uint256 tokenCount = auction.tokenCount;
        address highestBidder = auction.highestBidder;
        IERC721 erc721Contract = IERC721(tokenAddress);

        mapping(uint256 => uint256) storage tokenMap = auction.tokenIds;
        mapping(uint256 => bool) storage auctionTokens = auctionTokensERC721[tokenAddress];

        for (uint256 i; i < tokenCount;) {
            uint256 tokenId = tokenMap[i];
            auctionTokens[tokenId] = false;
            erc721Contract.transferFrom(theBarn, highestBidder, tokenId);

            unchecked {
                ++i;
            }
        }
    }

    function _transferERC1155s(Auction storage auction) internal {
        address tokenAddress = auction.tokenAddress;
        IERC1155 erc1155Contract = IERC1155(tokenAddress);
        uint256 tokenCount = auction.tokenCount;
        uint256[] memory tokenIds = new uint256[](tokenCount);
        uint256[] memory amounts = new uint256[](tokenCount);

        mapping(uint256 => uint256) storage tokenMap = auction.tokenIds;
        mapping(uint256 => uint256) storage amountMap = auction.amounts;
        mapping(uint256 => uint256) storage auctionTokens = auctionTokensERC1155[tokenAddress];

        for (uint256 i; i < tokenCount;) {
            uint256 tokenId = tokenMap[i];
            uint256 amount = amountMap[i];

            tokenIds[i] = tokenId;
            amounts[i] = amount;
            auctionTokens[tokenId] -= amount;

            unchecked {
                ++i;
            }
        }

        erc1155Contract.safeBatchTransferFrom(theBarn, auction.highestBidder, tokenIds, amounts, "");
    }

    function _resetERC721s(Auction storage auction) internal {
        address tokenAddress = auction.tokenAddress;
        uint256 tokenCount = auction.tokenCount;

        mapping(uint256 => uint256) storage tokenMap = auction.tokenIds;
        mapping(uint256 => bool) storage auctionTokens = auctionTokensERC721[tokenAddress];

        for (uint256 i; i < tokenCount;) {
            uint256 tokenId = tokenMap[i];
            auctionTokens[tokenId] = false;

            unchecked {
                ++i;
            }
        }
    }

    function _resetERC1155s(Auction storage auction) internal {
        address tokenAddress = auction.tokenAddress;
        uint256 tokenCount = auction.tokenCount;
        uint256[] memory tokenIds = new uint256[](tokenCount);
        uint256[] memory amounts = new uint256[](tokenCount);

        mapping(uint256 => uint256) storage tokenMap = auction.tokenIds;
        mapping(uint256 => uint256) storage amountMap = auction.amounts;
        mapping(uint256 => uint256) storage auctionTokens = auctionTokensERC1155[tokenAddress];

        for (uint256 i; i < tokenCount;) {
            uint256 tokenId = tokenMap[i];
            uint256 amount = amountMap[i];

            tokenIds[i] = tokenId;
            amounts[i] = amount;
            auctionTokens[tokenId] -= amount;

            unchecked {
                ++i;
            }
        }
    }

    function _checkAndResetERC721s(Auction storage auction) internal {
        address tokenAddress = auction.tokenAddress;
        uint256 tokenCount = auction.tokenCount;

        mapping(uint256 => uint256) storage tokenMap = auction.tokenIds;
        mapping(uint256 => bool) storage auctionTokens = auctionTokensERC721[tokenAddress];

        bool notRefundable = IERC721(tokenAddress).isApprovedForAll(theBarn, address(this));

        for (uint256 i; i < tokenCount;) {
            uint256 tokenId = tokenMap[i];
            auctionTokens[tokenId] = false;

            notRefundable = notRefundable && (IERC721(tokenAddress).ownerOf(tokenId) == theBarn);

            unchecked {
                ++i;
            }
        }

        if (notRefundable) {
            revert AuctionIsApproved();
        }
    }

    function _checkAndResetERC1155s(Auction storage auction) internal {
        address tokenAddress = auction.tokenAddress;
        uint256 tokenCount = auction.tokenCount;
        uint256[] memory tokenIds = new uint256[](tokenCount);
        uint256[] memory amounts = new uint256[](tokenCount);

        mapping(uint256 => uint256) storage tokenMap = auction.tokenIds;
        mapping(uint256 => uint256) storage amountMap = auction.amounts;
        mapping(uint256 => uint256) storage auctionTokens = auctionTokensERC1155[tokenAddress];

        bool notRefundable = IERC1155(tokenAddress).isApprovedForAll(theBarn, address(this));

        for (uint256 i; i < tokenCount;) {
            uint256 tokenId = tokenMap[i];
            uint256 amount = amountMap[i];

            tokenIds[i] = tokenId;
            amounts[i] = amount;
            auctionTokens[tokenId] -= amount;

            notRefundable = notRefundable && (IERC1155(tokenAddress).balanceOf(theBarn, tokenId) >= amount);

            unchecked {
                ++i;
            }
        }

        if (notRefundable) {
            revert AuctionIsApproved();
        }
    }
}
