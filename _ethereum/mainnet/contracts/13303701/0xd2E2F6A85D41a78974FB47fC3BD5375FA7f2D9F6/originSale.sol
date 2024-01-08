// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./AccessControl.sol";

contract originSale is AccessControl {
    uint256 public minBid;
    uint256 public aDay = 86400;

    bytes32 public constant CEO = keccak256("CEO");
    bytes32 public constant CTO = keccak256("CTO");
    bytes32 public constant CFO = keccak256("CFO");
    address internal _safe = 0xd8806d66E24b702e0A56fb972b75D24CAd656821;
    
    struct logBid {
        address bidder;
        uint256 id;
        uint256 bid;
        uint256 timestamp;
    }

    struct auction {
        bool began;
        bool ended;
        address highestBidder;
        uint256 highestBid;
        uint256 totalBids;
        uint256 timeEnded;
        uint256 timeStarted;
        mapping(uint256 => logBid) logBids;
    }
    
    mapping(uint256 => auction) public Auctions;

    enum state {START, BID, END}

    event getBids(state action, uint256 id, address bidder, uint256 bid, uint256 time);
    
    constructor(){
        minBid = 100000000000000000;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(CEO, address(0x47c06B50C2a6D28Ce3B130384b19a8929f414030));
        _setupRole(CFO, _safe);
        _setupRole(CTO, msg.sender);
    }

    modifier validate() {
        require(
            hasRole(CEO, msg.sender) ||
                hasRole(CFO, msg.sender) ||
                hasRole(CTO, msg.sender),
            "AccessControl: Address does not have valid Rights"
        );
        _;
    }

    function auctionStart(uint256 id) external payable {

        auction storage inst = Auctions[id];
        uint256 amount = msg.value;

        require(!inst.began, "Auction already started");
        require(!inst.ended, "Auction already ended");
        require(amount >= minBid, "Amount should be greater than minimum bid");

        emit getBids(state.START, id, msg.sender, msg.value, block.timestamp);
        
        inst.began = true;
        inst.highestBid = amount;
        inst.highestBidder = msg.sender;
        inst.timeStarted = block.timestamp;
        inst.timeEnded = block.timestamp + aDay;
    }

    function Bid(uint256 id) external payable returns(string memory) {

        uint256 amount = msg.value;
        auction storage inst = Auctions[id];
        
        require(inst.began, "Auction not yet started");
        require(!inst.ended, "Auction Finished");
        require(
            amount > inst.highestBid,
            "The bid amount should higher than current bid"
        );

        if (block.timestamp >= inst.timeEnded){
            this.auctionEnd(id);
            return "Auction ended";
        }
        payable(inst.highestBidder).transfer(inst.highestBid);

        emit getBids(state.BID, id, msg.sender, msg.value, block.timestamp);
        inst.highestBidder = msg.sender;
        inst.highestBid = amount;
        inst.logBids[inst.totalBids++] = logBid({
            bidder: inst.highestBidder,
            bid: inst.highestBid,
            timestamp: block.timestamp,
            id: id
        });

        return "Bid placed";
    }

    function auctionEnd(uint256 id) external payable returns(address) {
        
        auction storage inst = Auctions[id];
        require(inst.began, "Auction not yet started");
        require(!inst.ended, "Auction already Finished!");
        require(block.timestamp >= inst.timeEnded, "Auction Time Not yet finished");
        
        payable(_safe).transfer(inst.highestBid);
        emit getBids(state.END, id, msg.sender, inst.highestBid, block.timestamp);
        
        inst.ended = true;
        return inst.highestBidder;
    }

    function highestBid(uint256 id) public view returns(uint256) {
        return Auctions[id].highestBid;
    }

    function highestBidder(uint256 id) public view returns(address) {
        return Auctions[id].highestBidder;
    }

    function timeEnded(uint256 id) public view returns(uint256) {
        return Auctions[id].timeEnded;
    }
    
    function totalBids(uint256 id) public view returns(uint256) {
        return Auctions[id].totalBids;
    }
    
    function getLoggedBids(uint256 id, uint256 _bid) public view returns(address, uint256, uint256, uint256) {
        logBid storage inst = Auctions[id].logBids[_bid];
        return (inst.bidder, inst.bid, inst.timestamp, inst.id);
    }
    
    function auctionBegin(uint256 id) public view returns(bool) {
        return Auctions[id].began;
    }
    
    function auctionEnded(uint256 id) public view returns(bool) {
        return Auctions[id].ended;
    }

    function setBid(uint256 _val) public validate{
        minBid = _val;
    }
    
    function setTimer(uint256 _val) public validate{
        aDay = _val;
    }
    
    function setSafe(address _val) public validate{
        _safe = _val;
    }
    
}