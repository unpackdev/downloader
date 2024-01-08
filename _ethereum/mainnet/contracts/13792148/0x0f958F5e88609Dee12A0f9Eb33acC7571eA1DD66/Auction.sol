//SPDX-License-Identifier: Unlicensed
pragma solidity >= 0.8.0;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./EnumerableSet.sol";

interface IERC721 {
    function transferFrom(address, address, uint256) external;
    function safeTransferFrom(address, address, uint256) external;
    function safeTransferFrom(address, address, uint256, bytes memory) external;
}

contract Auction is Ownable {

    using SafeMath for uint256;

    using EnumerableSet for EnumerableSet.AddressSet;
    // onlyOwner can change controllers and transfer it's ownership
    EnumerableSet.AddressSet controller;

    bool                          public ready;
    bool                          public processed;
    
    struct BidStruct {
        address sender;  // sender address
        uint256 value;   // eth value
        uint256 time;    // unix timestamp UTC
    }
    mapping(uint256 => BidStruct) public bid_history;
    uint256                       public bid_count;

    address payable immutable     public owner_wallet;
    uint256 immutable             public auction_start;     
    uint256                       public auction_end;       
    uint256 immutable             public extend_time = 600; 
    uint256 immutable             public price_reserve;     
    uint256 immutable             public price_increment;   
    IERC721 immutable             public NFTContract;

    event Bid(address bidder, uint256 value, uint256 time);
    event AuctionWinningAmountPaid(address addr, uint256 amount);
    event controllerEvent(address _address, bool mode);

    constructor (
        uint256 _start,
        uint256 _end,
        uint256 _reserve,
        uint256 _increment,
        address payable _owner_wallet,
        address _NFTcontract
    ) {
        require(
            _start < _end,
            "Auction: Auction End must be higher than Auction Start"
        );
        require(
            _owner_wallet != address(0),
            "Auction: Owner Wallet cannot be 0x"
        );
        require(
            _NFTcontract != address(0),
            "Auction: NFT tracker address cannot be 0x"
        );

        auction_start = _start;
        auction_end = _end;
        price_reserve = _reserve;
        price_increment = _increment;
        owner_wallet = _owner_wallet;
        NFTContract = IERC721(_NFTcontract);
    }

    function bid() external payable isActive() {

        require(
            msg.value >= price_reserve,
            "Auction: Bid must be at least reserve"
        );

        BidStruct storage latestBid = bid_history[bid_count];

        require(
            msg.value >= latestBid.value.add(price_increment),
            "Auction: Bid must be at least last bid value plus increment"
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

        require(getTimestamp() > auction_end, "Auction: Auction has not ended yet");
        require(!processed, "Auction: Auction must not be processed");

        processed = true;
        BidStruct storage latestBid = bid_history[bid_count];
        
        require(latestBid.sender != address(0), "Auction: Auction winner cannot be address 0");

        NFTContract.transferFrom(address(this), latestBid.sender, 1);
        
        uint256 _value = address(this).balance;
        payable(owner_wallet).transfer(_value);

        AuctionWinningAmountPaid(latestBid.sender, latestBid.value);
    }

    // fallback method in case no bids occur
    function retrieveNFTOne() external onlyAllowed {
        require(bid_history[bid_count].sender == address(0), "Auction: Only if Auction has no winner");
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
        require(msg.sender == address(NFTContract), "Auction: Must be NFTContract address");
        require(receivedTokenId == 1, "Auction: Must be token id 1");
        ready = true;
        return this.onERC721Received.selector;
    }

    function getTimestamp() public view virtual returns (uint256) {
        return block.timestamp;
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

    //// Admin
    function setController(address _controller, bool _mode) public onlyOwner {
        if(_mode) {
            controller.add(_controller);
        } else {
            controller.remove(_controller);
        }
        emit controllerEvent(_controller, _mode);
    }

    function getControllerLength() public view returns (uint256) {
        return controller.length();
    }

    function getControllerAt(uint256 _index) public view returns (address) {
        return controller.at(_index);
    }

    function getControllerContains(address _addr) public view returns (bool) {
        return controller.contains(_addr);
    }

    function getControllers() public view returns (address[] memory) {
        return controller.values();
    }


    //// blackhole prevention methods / drain
    function drain() external onlyAllowed isProcessed {
        payable(owner()).transfer(address(this).balance);
    }

    function retrieveERC20(address _tracker, uint256 amount) external onlyAllowed isProcessed {
        IERC20(_tracker).transfer(msg.sender, amount);
    }

    function retrieve721(address _tracker, uint256 id) external onlyAllowed isProcessed {
        IERC721(_tracker).transferFrom(address(this), msg.sender, id);
    }


    //// Modifiers
    modifier isActive() {
        require(isAuctionActive(), "Auction: Auction is not active");
        _;
    }

    modifier isProcessed() {
        require(processed, "Auction: Auction must be processed");
        _;
    }

    modifier onlyAllowed() {
        require(
            msg.sender == owner() || controller.contains(msg.sender),
            "Auction: Not Authorised"
        );
        _;
    }
}
