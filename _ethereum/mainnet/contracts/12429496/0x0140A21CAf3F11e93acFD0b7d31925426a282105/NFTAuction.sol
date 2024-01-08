// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./Context.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./Address.sol";
import "./MarketTradingAccessControls.sol";
import "./IMarketTradingNFT.sol";

/**
 * @notice Primary sale auction contract for MarketTrading NFTs
 */
contract NFTAuction is Context, ReentrancyGuard {
    using SafeMath for uint256;
    using Address for address payable;

    /// @notice Event emitted only on construction. To be used by indexers
    event NFTAuctionContractDeployed();

    event PauseToggled(
        bool isPaused
    );

    event UpdateAccessControls(
        address indexed accessControls
    );

    event UpdatePlatformFeeRecipient(
        address payable platformFeeRecipient
    );

    event UpdatePlatformFee(
        uint256 platformFee
    );

    event UpdateResellFee(
        uint256 resellFee
    );

    event UpdateCancelFee(
        uint256 cancelFee
    );

    event UpdateMinBidIncrement(
        uint256 minBidIncrement
    );

    event UpdateBidLockTime(
        uint256 bidLockTime
    );

    event UpdateAuctionStatus(
        string igUrl,
        bool status
    );

    event BidPlaced(
        string igUrl,
        string edition,
        address indexed bidder,
        uint256 bid
    );

    event BidWithdrawn(
        string indexed igUrl,
        address indexed bidder,
        uint256 bid
    );

    event BidRefunded(
        address indexed bidder,
        uint256 bid
    );

    event AuctionResulted(
        uint256 indexed tokenId,
        address seller,
        string tokenUri,
        string edition,
        address indexed winner,
        uint256 winningBid
    );

    /// @notice Information about the sender that placed a bit on an auction
    struct HighestBid {
        address payable bidder;
        uint256 bid;
        uint256 lastBidTime;
    }

    struct AuctionDetail {
        uint256 tokenId;
        address owner;
    }

    /// @notice instagram URL -> highest bidder info (if a bid has been received)
    mapping(string => HighestBid) public highestBids;

    /// @notice instagram URL -> Auction finished info 
    mapping(string => AuctionDetail) public auctionDetails;

    /// @notice NFT - the only NFT that can be auctioned in this contract
    IMarketTradingNFT public marketTradingNft;

    /// @notice responsible for enforcing admin access
    MarketTradingAccessControls public accessControls;
    
    /// @notice globally bid lock time, bidders can't withdraw bid before bidLockTime.
    uint256 public bidLockTime = 1 days;

    /// @notice globally and across all auctions, the amount by which a bid has to increase
    uint256 public minBidIncrement = 0.01 ether;

    /// @notice global platform fee, assumed to always be to 1 decimal place i.e. 50 = 5.0%
    uint256 public platformFee = 50;

    /// @notice global resell platform fee, assumed to always be to 1 decimal place i.e. 25 = 2.5%
    uint256 public resellFee = 25;

    /// @notice global creator fee, assumed to always be to 1 decimal place i.e. 100 = 10.0%
    uint256 public creatorFee = 100;

    /// @notice global cancel fee, assumed to always be to 1 decimal place i.e. 50 = 5.0%
    uint256 public cancelFee = 50;

    /// @notice where to send platform fee funds to
    address payable public platformFeeRecipient;

    /// @notice for switching off auction creations, bids and withdrawals
    bool public isPaused;

    modifier whenNotPaused() {
        require(!isPaused, "Function is currently paused");
        _;
    }

    constructor(
        MarketTradingAccessControls _accessControls,
        IMarketTradingNFT _marketTradingNft,
        address payable _platformFeeRecipient
    ) public {
        // Check inputed addresses are not zero address
        require(address(_accessControls) != address(0), "NFTAuction: Invalid Access Controls");
        require(address(_marketTradingNft) != address(0), "NFTAuction: Invalid NFT");
        require(_platformFeeRecipient != address(0), "NFTAuction: Invalid Platform Fee Recipient");

        accessControls = _accessControls;
        marketTradingNft = _marketTradingNft;
        platformFeeRecipient = _platformFeeRecipient;

        emit NFTAuctionContractDeployed();
    }


    /**
     @notice Places a new bid, out bidding the existing bidder if found and criteria is reached
     @dev Only callable when the auction is open
     @dev Bids from smart contracts are prohibited to prevent griefing with always reverting receiver
     @param _igUrl Instagram URL of the fake NFT
     */
    function placeBid(string memory _igUrl) external payable nonReentrant whenNotPaused {
        require(_msgSender().isContract() == false, "NFTAuction.placeBid: No contracts permitted");

        uint256 bidAmount = msg.value;

        // Ensure bid adheres to outbid increment and threshold
        HighestBid storage highestBid = highestBids[_igUrl];
        uint256 minBidRequired = highestBid.bid.add(minBidIncrement);
        require(bidAmount >= minBidRequired, "NFTAuction.placeBid: Failed to outbid highest bidder");

        // Refund existing top bidder if found
        if (highestBid.bidder != address(0)) {
            _refundHighestBidder(highestBid.bidder, highestBid.bid);
        }

        // assign top bidder and bid time
        highestBid.bidder = _msgSender();
        highestBid.bid = bidAmount;
        highestBid.lastBidTime = _getNow();

        emit BidPlaced(_igUrl, "1 of 1", _msgSender(), bidAmount);
    }

    /**
     @notice Given a sender who has the highest bid on a NFT, allows them to withdraw their bid
     @dev Only callable by the existing top bidder
     @param _igUrl Instagram URL of the fake NFT
     */
    function withdrawBid(string memory _igUrl) external nonReentrant whenNotPaused {
        HighestBid storage highestBid = highestBids[_igUrl];

        // Ensure highest bidder is the caller
        require(highestBid.bidder == _msgSender(), "NFTAuction.withdrawBid: You are not the highest bidder");

        require(_getNow() >= highestBid.lastBidTime + bidLockTime, "NFTAuction.withdrawBid: Can't withdraw before locktime passed");

        uint256 previousBid = highestBid.bid;

        // Clean up the existing top bid
        delete highestBids[_igUrl];

        // Refund the top bidder
        _refundHighestBidder(_msgSender(), previousBid);

        emit BidWithdrawn(_igUrl, _msgSender(), previousBid);
    }

    //////////
    // Admin /
    //////////

    /**
     @notice Results a finished auction
     @dev Only admin or smart contract
     @dev Auction can only be resulted if there has been a bidder and reserve met.
     @dev If there have been no bids, the auction needs to be cancelled instead using `cancelAuction()`
     @param _igUrl Instagram URL of the fake NFT
     @param _seller The creator of Instagram Post
     */
    function resultAuction(string memory _igUrl, address _seller) external nonReentrant {
        require(
            accessControls.hasAdminRole(_msgSender()) || accessControls.hasSmartContractRole(_msgSender()),
            "NFTAuction.resultAuction: Sender must be admin or smart contract"
        );

        // Ensure seller is not zero address
        require(_seller != address(0), "NFTAuction.resultAuction: Seller should not be zero address");

        // Get info on who the highest bidder is
        HighestBid storage highestBid = highestBids[_igUrl];
        address winner = highestBid.bidder;
        uint256 winningBid = highestBid.bid;
        uint256 maxShare = 1000;

        // Ensure there is a winner
        require(winner != address(0), "NFTAuction.resultAuction: no open bids");

        // Clean up the highest bid
        delete highestBids[_igUrl];
        
        AuctionDetail storage auctionDetail = auctionDetails[_igUrl];

        uint256 platformFeeInETH;
        uint256 creatorFeeInETH;

        if (auctionDetail.tokenId == 0)
        {
            // Mint NFT to the highest bidder.
            uint256 _tokenId = marketTradingNft.mint(winner, _igUrl, _seller);
            auctionDetail.tokenId = _tokenId;
            auctionDetail.owner = winner;

            // Work out platform fee from above reserve amount
            platformFeeInETH = winningBid.mul(platformFee).div(maxShare);
        }
        else {
            // Transfer NFT to the new higgest bidder
            require(marketTradingNft.ownerOf(auctionDetail.tokenId) == _seller,"NFTAuction.resultAuction: seller is not owner of NFT");

            marketTradingNft.safeTransferFrom(auctionDetail.owner, winner, auctionDetail.tokenId);
            auctionDetail.owner = winner;

            // Work out platform fee and creator fee from above reserve amount
            platformFeeInETH = winningBid.mul(resellFee).div(maxShare);
            creatorFeeInETH = winningBid.mul(creatorFee).div(maxShare);
        }

        // Record the primary sale price for the NFT
        marketTradingNft.setPrimarySalePrice(auctionDetail.tokenId, winningBid);

        // Send platform fee
        (bool platformTransferSuccess,) = platformFeeRecipient.call{value : platformFeeInETH}("");
        require(platformTransferSuccess, "NFTAuction.resultAuction: Failed to send platform fee");

        // Send remaining to seller
        (bool sellerTransferSuccess,) = _seller.call{value : winningBid.sub(platformFeeInETH).sub(creatorFeeInETH)}("");
        require(sellerTransferSuccess, "NFTAuction.resultAuction: Failed to send the instagram post creator their royalties");

        if(creatorFeeInETH > 0) {
            // Send creator fee
            (bool creatorTransferSuccess,) = marketTradingNft.postCreators(auctionDetail.tokenId).call{value : creatorFeeInETH}("");
            require(creatorTransferSuccess, "NFTAuction.resultAuction: Failed to send creator fee");
        }

        emit AuctionResulted(auctionDetail.tokenId, _seller, _igUrl, "1 of 1", winner, winningBid.sub(platformFeeInETH));
    }

    /**
     @notice Toggling the pause flag
     @dev Only admin
     */
    function toggleIsPaused() external {
        require(accessControls.hasAdminRole(_msgSender()), "NFTAuction.toggleIsPaused: Sender must be admin");
        isPaused = !isPaused;
        emit PauseToggled(isPaused);
    }
    
    /**
     @notice Update the amount by which bids have to increase, across all auctions
     @dev Only admin
     @param _minBidIncrement New bid step in WEI
     */
    function updateMinBidIncrement(uint256 _minBidIncrement) external {
        require(accessControls.hasAdminRole(_msgSender()), "NFTAuction.updateMinBidIncrement: Sender must be admin");
        minBidIncrement = _minBidIncrement;
        emit UpdateMinBidIncrement(_minBidIncrement);
    }

    /**
     @notice Update the lock time of the higgest bid, before locktime passed the highest bidder can't cancel the auction
     @dev Only admin
     @param _bidLockTime New bid lock time
     */
    function updateBidLockTime(uint256 _bidLockTime) external {
        require(accessControls.hasAdminRole(_msgSender()), "NFTAuction.updateBidLockTime: Sender must be admin");
        bidLockTime = _bidLockTime;
        emit UpdateBidLockTime(_bidLockTime);
    }   

    /**
     @notice Method for updating the access controls contract used by the NFT
     @dev Only admin
     @param _accessControls Address of the new access controls contract (Cannot be zero address)
     */
    function updateAccessControls(MarketTradingAccessControls _accessControls) external {
        require(
            accessControls.hasAdminRole(_msgSender()),
            "NFTAuction.updateAccessControls: Sender must be admin"
        );

        require(address(_accessControls) != address(0), "NFTAuction.updateAccessControls: Zero Address");

        accessControls = _accessControls;
        emit UpdateAccessControls(address(_accessControls));
    }

    /**
     @notice Method for updating platform fee address
     @dev Only admin
     @param _platformFeeRecipient payable address the address to sends the funds to
     */
    function updatePlatformFeeRecipient(address payable _platformFeeRecipient) external {
        require(
            accessControls.hasAdminRole(_msgSender()),
            "NFTAuction.updatePlatformFeeRecipient: Sender must be admin"
        );

        require(_platformFeeRecipient != address(0), "NFTAuction.updatePlatformFeeRecipient: Zero address");

        platformFeeRecipient = _platformFeeRecipient;
        emit UpdatePlatformFeeRecipient(_platformFeeRecipient);
    }

    /**
     @notice Method for updating platform fee 
     @dev Only admin
     @param _platformFee New platform fee
     */
    function updatePlatformFee(uint256 _platformFee) external {
        require(
            accessControls.hasAdminRole(_msgSender()),
            "NFTAuction.updatePlatformFee: Sender must be admin"
        );

        platformFee = _platformFee;
        emit UpdatePlatformFee(_platformFee);
    }

    /**
     @notice Method for updating resell fee 
     @dev Only admin
     @param _resellFee New resell fee
     */
    function updateResellFee(uint256 _resellFee) external {
        require(
            accessControls.hasAdminRole(_msgSender()),
            "NFTAuction.updateResellFee: Sender must be admin"
        );

        resellFee = _resellFee;
        emit UpdateResellFee(_resellFee);
    }

    /**
     @notice Method for updating cancel fee 
     @dev Only admin
     @param _cancelFee New cancel fee
     */
    function updateCancelFee(uint256 _cancelFee) external {
        require(
            accessControls.hasAdminRole(_msgSender()),
            "NFTAuction.updateCancelFee: Sender must be admin"
        );

        cancelFee = _cancelFee;
        emit UpdateCancelFee(_cancelFee);
    }
    ///////////////
    // Accessors //
    ///////////////

    /**
     @notice Method for getting all info about the highest bidder
     @param _igUrl Instagram URL of the fake NFT
     */
    function getHighestBidder(string memory _igUrl) external view returns (address payable _bidder, uint256 _bid, uint256 _lastBidTime) {
        HighestBid storage highestBid = highestBids[_igUrl];
        return (highestBid.bidder, highestBid.bid, highestBid.lastBidTime);
    }

    /////////////////////////
    // Internal and Private /
    /////////////////////////

    function _getNow() internal virtual view returns (uint256) {
        return block.timestamp;
    }

    /**
     @notice Used for sending back escrowed funds from a previous bid
     @param _currentHighestBidder Address of the last highest bidder
     @param _currentHighestBid Ether amount in WEI that the bidder sent when placing their bid
     */
    function _refundHighestBidder(address payable _currentHighestBidder, uint256 _currentHighestBid) private {
        uint256 maxShare = 1000;

        // Work out platform fee from above reserve amount
        uint256 platformFeeInETH = _currentHighestBid.mul(cancelFee).div(maxShare);

        // Send platform fee
        (bool platformTransferSuccess,) = platformFeeRecipient.call{value : platformFeeInETH}("");
        require(platformTransferSuccess, "NFTAuction._refundHighestBidder: Failed to send platform fee");

        // refund previous highest bid - platform fee (if bid exists)
        (bool successRefund,) = _currentHighestBidder.call{value : _currentHighestBid.sub(platformFeeInETH)}("");
        require(successRefund, "NFTAuction._refundHighestBidder: failed to refund previous bidder");

        emit BidRefunded(_currentHighestBidder, _currentHighestBid.sub(platformFeeInETH));
    }
}
