//"SPDX-License-Identifier: UNLICENSED"
pragma solidity 0.6.6;

import "./Counters.sol";
import "./ReentrancyGuard.sol";
import "./ERC721.sol";
import "./ERC20.sol";
import "./IERC721Receiver.sol";
import "./ERC721Holder.sol";
import "./GoldFeverNativeGold.sol";

// import "./GoldFeverItem.sol";

contract GoldFeverAuction is ReentrancyGuard, IERC721Receiver, ERC721Holder {
    bytes32 public constant CREATED = keccak256("CREATED");
    bytes32 public constant BID = keccak256("BID");
    bytes32 public constant FINISHED = keccak256("FINISHED");

    using Counters for Counters.Counter;
    Counters.Counter private _auctionIds;

    IERC20 ngl;

    uint256 public constant build = 3;

    constructor(address ngl_) public {
        ngl = IERC20(ngl_);
    }

    enum Status {
        active,
        finished
    }

    event AuctionCreated(
        uint256 auctionId,
        address nftContract,
        uint256 nftId,
        address owner,
        uint256 startingPrice,
        uint256 startTime,
        uint256 duration,
        uint256 biddingStep
    );
    event AuctionBid(uint256 auctionId, address bidder, uint256 price);
    event Claim(uint256 auctionId, address winner);

    struct Auction {
        uint256 auctionId;
        address nftContract;
        uint256 nftId;
        address owner;
        uint256 startTime;
        uint256 startingPrice;
        uint256 biddingStep;
        uint256 duration;
        uint256 highestBidAmount;
        address highestBidder;
        bytes32 status;
    }
    mapping(uint256 => Auction) public idToAuction;

    function createAuction(
        address nftContract,
        uint256 nftId,
        uint256 startingPrice,
        uint256 startTime,
        uint256 duration,
        uint256 biddingStep
    ) public nonReentrant returns (uint256) {
        _auctionIds.increment();
        uint256 auctionId = _auctionIds.current();

        idToAuction[auctionId] = Auction(
            auctionId,
            nftContract,
            nftId,
            msg.sender,
            startTime,
            startingPrice,
            biddingStep,
            duration,
            startingPrice,
            address(0),
            CREATED
        );

        IERC721(nftContract).safeTransferFrom(msg.sender, address(this), nftId);

        emit AuctionCreated(
            auctionId,
            nftContract,
            nftId,
            msg.sender,
            startingPrice,
            startTime,
            duration,
            biddingStep
        );
        return auctionId;
    }

    function bid(uint256 auctionId, uint256 price)
        public
        nonReentrant
        returns (bool)
    {
        uint256 startDate = idToAuction[auctionId].startTime;
        uint256 endDate = idToAuction[auctionId].startTime +
            idToAuction[auctionId].duration;
        require(
            block.timestamp >= startDate && block.timestamp < endDate,
            "Auction is finished or not started yet"
        );
        if (idToAuction[auctionId].status == CREATED) {
            require(
                price >= idToAuction[auctionId].startingPrice,
                "Must bid equal or higher than current startingPrice"
            );

            ngl.transferFrom(msg.sender, address(this), price);
            idToAuction[auctionId].highestBidAmount = price;
            idToAuction[auctionId].highestBidder = msg.sender;
            idToAuction[auctionId].status = BID;
            emit AuctionBid(auctionId, msg.sender, price);
            return true;
        }
        if (idToAuction[auctionId].status == BID) {
            require(
                price >=
                    idToAuction[auctionId].highestBidAmount +
                        idToAuction[auctionId].biddingStep,
                "Must bid higher than current highest bid"
            );

            ngl.transferFrom(msg.sender, address(this), price);
            if (idToAuction[auctionId].highestBidder != address(0)) {
                // return ngl to the previuos bidder
                ngl.transfer(
                    idToAuction[auctionId].highestBidder,
                    idToAuction[auctionId].highestBidAmount
                );
            }

            // register new bidder
            idToAuction[auctionId].highestBidder = msg.sender;
            idToAuction[auctionId].highestBidAmount = price;

            emit AuctionBid(auctionId, msg.sender, price);
            return true;
        }
        return false;
    }

    function getCurrentBidOwner(uint256 auctionId)
        public
        view
        returns (address)
    {
        return idToAuction[auctionId].highestBidder;
    }

    function getCurrentBidAmount(uint256 auctionId)
        public
        view
        returns (uint256)
    {
        return idToAuction[auctionId].highestBidAmount;
    }

    function isFinished(uint256 auctionId) public view returns (bool) {
        return getStatus(auctionId) == Status.finished;
    }

    function getStatus(uint256 auctionId) public view returns (Status) {
        uint256 expiry = idToAuction[auctionId].startTime +
            idToAuction[auctionId].duration;
        if (block.timestamp >= expiry) {
            return Status.finished;
        } else {
            return Status.active;
        }
    }

    function getWinner(uint256 auctionId) public view returns (address) {
        require(isFinished(auctionId), "Auction is not finished");
        return idToAuction[auctionId].highestBidder;
    }

    function claimItem(uint256 auctionId) private {
        address winner = getWinner(auctionId);
        require(winner != address(0), "There is no winner");
        address nftContract = idToAuction[auctionId].nftContract;

        IERC721(nftContract).safeTransferFrom(
            address(this),
            winner,
            idToAuction[auctionId].nftId
        );
        emit Claim(auctionId, winner);
    }

    function finalizeAuction(uint256 auctionId) public nonReentrant {
        require(isFinished(auctionId), "Auction is not finished");
        require(
            idToAuction[auctionId].status != FINISHED,
            "Auction is already finalized"
        );
        if (idToAuction[auctionId].highestBidder == address(0)) {
            IERC721(idToAuction[auctionId].nftContract).safeTransferFrom(
                address(this),
                idToAuction[auctionId].owner,
                idToAuction[auctionId].nftId
            );
            idToAuction[auctionId].status == FINISHED;
        } else {
            ngl.transfer(
                idToAuction[auctionId].owner,
                idToAuction[auctionId].highestBidAmount
            );
            claimItem(auctionId);
            idToAuction[auctionId].status == FINISHED;
        }
    }
}
