//SPDX-License-Identifier: Unlicensed
pragma solidity >=0.6.0 <0.8.0;

import "./console.sol";

import "./IECNFT.sol";

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeMath.sol";


contract ECAuction is Ownable {

    using SafeMath for uint256;

    bool                          public ready;
    bool                          public processed;
    
    struct BidStruct {
        address sender;  // sender address
        uint256 value;   // eth value
        uint256 time;    // unix timestamp UTC
    }
    mapping(uint256 => BidStruct) public bid_history;
    uint256                       public bid_count;

    address payable immutable     public creator_wallet;
    address payable immutable     public owner_wallet;
    uint256 immutable             public creator_fee_percentage;
    uint256 immutable             public auction_start;     
    uint256                       public auction_end;       
    uint256 immutable             public extend_time = 600; 
    uint256 immutable             public price_reserve;     
    uint256 immutable             public price_increment;   
    IECNFT  immutable             public NFTContract;

    event Bid(address bidder, uint256 value, uint256 time);
    event AuctionWinningAmountPaid(address addr, uint256 amount);

    constructor (
        uint256 _start,
        uint256 _end,
        uint256 _reserve,
        uint256 _increment,
        address payable _owner_wallet,
        address payable _creator_wallet,
        uint256 _creator_fee,
        address _NFTcontract
    ) {
        require(
            _start < _end,
            "Construct: Auction End must be higher than Auction Start"
        );
        require(
            _owner_wallet != address(0),
            "Construct: Owner Wallet cannot be 0x"
        );
        require(
            _creator_wallet != address(0),
            "Construct: Creator Wallet cannot be 0x"
        );

        require(
            _NFTcontract != address(0),
            "Construct: NFT tracker address cannot be 0x"
        );

        auction_start = _start;
        auction_end = _end;
        price_reserve = _reserve;
        price_increment = _increment;
        owner_wallet = _owner_wallet;
        creator_wallet = _creator_wallet;
        creator_fee_percentage = _creator_fee;
        NFTContract = IECNFT(_NFTcontract);
    }

    function bid() external payable isActive() {

        require(
            msg.value >= price_reserve,
            "Bid must be at least reserve"
        );

        BidStruct storage latestBid = bid_history[bid_count];

        require(
            msg.value >= latestBid.value.add(price_increment),
            "Bid must be at least last bid value plus increment"
        );


        // register new bid
        registerBidToHistory(msg.sender, msg.value);

        // if current bid is happening in the last 10 minutes of the auction, increase end by 10 minutes
        if(getTimestamp() > auction_end.sub(extend_time)) {
            auction_end = getTimestamp().add(extend_time);
        }

        if(bid_count > 1) {
            // return old bid value
            payable(latestBid.sender).transfer(latestBid.value);
        }
    }

    function registerBidToHistory(address _sender, uint256 _value) internal {
        BidStruct storage thisBid = bid_history[++bid_count];
        thisBid.sender = _sender;
        thisBid.value = _value;
        thisBid.time = getTimestamp();

        Bid(_sender, _value, thisBid.time);
    }

    function processAuction() external {

        require(getTimestamp() > auction_end, "Auction has not ended yet");
        require(!processed, "Auction must not be processed");

        processed = true;
        BidStruct storage latestBid = bid_history[bid_count];
        
        require(latestBid.sender != address(0), "Auction winner cannot be address 0");

        NFTContract.transferFrom(address(this), latestBid.sender, 1);
        
        uint256 _value = address(this).balance;
        uint256 creatorPart = _value.mul(creator_fee_percentage).div(100);
        uint256 ownerPart = _value.sub(creatorPart);
        payable(creator_wallet).transfer(creatorPart);
        payable(owner_wallet).transfer(ownerPart);

        AuctionWinningAmountPaid(latestBid.sender, latestBid.value);
    }

    // fallback method in case no bids occur
    function retrieveNFTOne() external onlyOwner {
        require(bid_history[bid_count].sender == address(0), "Only if Auction has no winner");
        ready = false;
        NFTContract.transferFrom(address(this), msg.sender, 1);
    }

    /*
     *  Receive token {1} that is going to be auctioned
     */
    function onERC721Received(
        address,        // operator
        address,        // from,
        uint256 receivedTokenId,
        bytes memory    // data
    ) external returns (bytes4) {
        require(msg.sender == address(NFTContract), "Must be NFTContract address");
        require(receivedTokenId == 1, "Must be token id 1");
        ready = true;
        return this.onERC721Received.selector;
    }

    function getTimestamp() public view virtual returns (uint256) {
        return block.timestamp;
    }

    //// Blackhole prevention methods
    function drain() external onlyOwner isProcessed {
        payable(owner()).transfer(address(this).balance);
    }

    function retrieveERC20(address _tracker, uint256 amount) external onlyOwner isProcessed {
        IERC20(_tracker).transfer(msg.sender, amount);
    }

    function retrieve721(address _tracker, uint256 id) external onlyOwner isProcessed {
        IECNFT(_tracker).transferFrom(address(this), msg.sender, id);
    }

    //// Web3 helper methods
    function getLatestBid() external view returns (address sender, uint256 value, uint256 time) {
        BidStruct storage thisBid = bid_history[bid_count];
        return (
            thisBid.sender,
            thisBid.value,
            thisBid.time
        );
    }

    function isAuctionActive() public view returns (bool) {
        if(!ready) {
            return false;
        }
        uint256 timestamp = getTimestamp();
        if(auction_start <= timestamp && timestamp <= auction_end) {
            return true;
        }
        return false;
    }

    //// Modifiers
    modifier isActive() {
        require(isAuctionActive(), "Auction is not active");
        _;
    }

    modifier isProcessed() {
        require(processed, "Auction must be processed");
        _;
    }
}
