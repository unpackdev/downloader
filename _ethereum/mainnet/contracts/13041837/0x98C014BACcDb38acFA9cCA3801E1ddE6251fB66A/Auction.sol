// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./SafeMath.sol";
import "./Ownable.sol";
import "./User.sol";
import "./Domain.sol";
import "./Settings.sol";
import "./Utils.sol";

contract Auction is Ownable {

    using SafeMath for uint256;
    bool public initialized;
    Settings settings;
    struct Bid {
      address bidder;
      uint256 amount;
      uint256 canCancelAfter;
    }
    
    mapping(bytes32=>Bid[10]) bids;
    mapping(bytes32=>uint256) minimumAcceptedBid;
    bytes32[] hashes;
    mapping(bytes32=>uint256) hashFirstSeen;
    event Refund(bytes32 hash,
                 address bidder,
                 uint256 amount);

    event BidUpdate(bytes32 hash,
                    address bidder,
                    uint256 amount,
                    uint256 originalAmount);
    
    event BidPlaced(bytes32 hash,
                    address bidder,
                    uint256 amount);
    
    event BidAccepted(bytes32 hash,
                      address winningBidder,
                      uint256 bidAmount,
                      address sellerAddress,
                      uint256 tokenId,
                      uint256 winningAmount,
                      uint256 fee);
    
    constructor(){        
    }

    function initialize(Settings _settings) public onlyOwner {
      require(!initialized, "Contract instance has already been initialized");
      initialized = true;
      settings = _settings;
    }

    function setSettingsAddress(Settings _settings) public onlyOwner {
        settings = _settings;
    }
    
    function systemFee() public view returns(uint256){
        return settings.getNamedUint("AUCTION_FEE");
    }

    
    function getMaxDepth() public view returns(uint256){
        return settings.getNamedUint("AUCTION_MAX_DEPTH");
    }

    function getCancelAfter() public view returns(uint256){
        return settings.getNamedUint("AUCTION_CANCEL_AFTER");
    }
    
    modifier onlyActiveUser () {
        require(domain().canTransferTo(msg.sender), "Must be active user");
        _;
    }

    function bidAt(bytes32 hash, uint256 index) public view returns(Bid memory){
        if(isValidBidIndex(index)){
            return bids[hash][index];
        }
        return Bid(address(0),0,0);
    }
    
    function lowestBidAt(bytes32 hash) public view returns(uint256){
        uint256 minBid = 0;
        uint256 minBidAt = getMaxDepth().add(1);
        for(uint256 _i = 0; _i < bids[hash].length; _i++){
            if(minBid > bids[hash][_i].amount){
                minBidAt = _i;
                minBid = bids[hash][_i].amount;
            }
        }
        return minBidAt;
    }
    
    function highestBidAt(bytes32 hash) public view returns(uint256){
        uint256 maxBid = 0;
        uint256 maxBidAt = getMaxDepth().add(1);
        for(uint256 _i = 0; _i < bids[hash].length; _i++){
            if(maxBid < bids[hash][_i].amount){
                maxBidAt = _i;
                maxBid = bids[hash][_i].amount;
            }
        }
        return maxBidAt;
    }

    function highestBidValue(bytes32 hash) public view returns(uint256){
        uint256 _highestBidIndex = highestBidAt(hash);
        if(isValidBidIndex(_highestBidIndex)){
            return bids[hash][_highestBidIndex].amount;
        }
        return 0;
    }

    function highestBidder(bytes32 hash) public view returns(address){
        uint256 _highestBidIndex = highestBidAt(hash);
        if(isValidBidIndex(_highestBidIndex)){
            return bids[hash][_highestBidIndex].bidder;
        }
        return address(0);
    }
    function bidsCount(bytes32 hash) public view returns(uint256){
        uint256 count = 0;
        for(uint256 _i = 0; _i < bids[hash].length; _i++){
            if(bids[hash][_i].amount > 0){
                count = count + 1;
            }
        }
        return count;
    }

    function firstEmptyBidSlot(bytes32 hash) public view returns(uint256){
        for(uint256 _i = 0; _i < bids[hash].length; _i++){
            if(bids[hash][_i].amount == 0){
                return _i;
            }
        }
        return getMaxDepth().add(1);
    }
    
    function currentBidOfAt(bytes32 hash, address bidder) public view returns(uint256){
        for(uint256 _i = 0; _i < bids[hash].length; _i++){
            if(bids[hash][_i].bidder == bidder){
                return _i;
            }
        }
        return getMaxDepth().add(1);
    }

    function isValidBidIndex(uint256 _index) public view returns(bool){
        return getMaxDepth() > _index;
    }
        
    function getCurrentBidAmountOf(bytes32 hash, address bidder) public view returns(uint256){
      uint256 currentBidIndex = currentBidOfAt(hash, bidder);
      if(!isValidBidIndex( currentBidIndex)){
        return 0;
      }
      return bids[hash][currentBidIndex].amount;
    }

    function refundLowestBid(bytes32 hash) internal returns(uint256){
        uint256 _lowestBidIndex = lowestBidAt(hash);
        if(!isValidBidIndex(_lowestBidIndex)){
            uint256 firstEmptySlotIndex = firstEmptyBidSlot(hash);
            if(!isValidBidIndex(firstEmptySlotIndex)){
                revert("No empty slots");
            }
            return firstEmptySlotIndex;
        }
        address payable bidder = payable(bids[hash][_lowestBidIndex].bidder);
        uint256 amount = bids[hash][_lowestBidIndex].amount;
        if(amount > 0){
            delete bids[hash][_lowestBidIndex];
            bidder.transfer(amount);
            emit Refund(hash, bidder, amount);
        }
        return _lowestBidIndex;
    }
    function hashesCount() public view returns(uint256){
      return hashes.length;
    }
    function hashAt(uint256 _index) public view returns(bytes32){
      return hashes[_index];
    }
    function nameAt(uint256 _index) public view returns(string memory){
      return domain().registryReveal(hashAt(_index));
    }
    function logHash(bytes32 hash) internal {
      if(hashFirstSeen[hash] == 0){
        hashFirstSeen[hash] = block.timestamp;
        hashes.push(hash);
      }
    }
    
    function bidOnHash(bytes32 hash) public payable onlyActiveUser returns(bool){
        uint256 currentBidIndex = currentBidOfAt(hash, msg.sender);
        uint256 bidAmount = msg.value;
        if(isValidBidIndex(currentBidIndex)){ // user already has a bid
            bidAmount = bidAmount.add(bids[hash][currentBidIndex].amount);
        }
        require(bidAmount > Utils.percentageCentsMax(), "Minimum bid not reached");
        require(bidAmount > highestBidValue(hash), "bid amount is not high enough");
        require(bidAmount >= minimumAcceptedBid[hash], "minimum bid not reached");
        if(isValidBidIndex(currentBidIndex)){
            bids[hash][currentBidIndex].amount = bidAmount;
            bids[hash][currentBidIndex].canCancelAfter = block.timestamp.add(getCancelAfter());
            emit BidUpdate(hash, msg.sender, bidAmount, bidAmount.sub(msg.value));
            return true;
        }
        uint256 emptiedSlotIndex = refundLowestBid(hash);
        if(!isValidBidIndex(emptiedSlotIndex)){
            revert("not a valid empty slot");
        }
        bids[hash][emptiedSlotIndex] = Bid(msg.sender, bidAmount, block.timestamp.add(getCancelAfter()));
        if(minimumAcceptedBid[hash] == 0){
          minimumAcceptedBid[hash] = bidAmount;
        }
        logHash(hash);
        emit BidPlaced(hash, msg.sender, bidAmount);
        return true;
    }

    function domain() public view returns(Domain){
      return Domain(settings.getNamedAddress("DOMAIN"));
    }
    
    function bidOnName(string memory _name) public payable onlyActiveUser returns(bool){
      bytes32 hash = domain().registryDiscover(_name);
      return bidOnHash(hash);
    }
    function getMinimumAcceptedBid(bytes32 hash) public view returns(uint256){
      if(minimumAcceptedBid[hash] > 0){
        return minimumAcceptedBid[hash];
      }
      return Utils.percentageCentsMax();
    }
    function updateAuction(bytes32 hash, uint256 minimumBid) public onlyActiveUser {
      uint256 tokenId = domain().tokenIdForHash(hash);
      require(domain().tokenExists(tokenId), "token does not exist");
      require(domain().ownerOf(tokenId) == msg.sender, "token does not belong to user");
      minimumAcceptedBid[hash] = minimumBid;
      logHash(hash);
    }
    
    function acceptHighestBid(bytes32 hash) public onlyActiveUser{
      if(minimumAcceptedBid[hash] > 0){
        acceptLimitBid(hash, minimumAcceptedBid[hash]);
      }else{
        acceptLimitBid(hash, Utils.percentageCentsMax());
      }
    }

    function feeDestination() public view returns(address){
        return settings.getNamedAddress("TLD");
    }
    
  
    function acceptLimitBid(bytes32 hash, uint256 _limitAmount) public onlyActiveUser {
      uint256 tokenId = domain().tokenIdForHash(hash);
      require(domain().tokenExists(tokenId), "token does not exist");
      require(domain().ownerOf(tokenId) == msg.sender, "token does not belong to user");
      require(domain().getApproved(tokenId) == address(this), "token must be approved for contract");
      uint256 highestBidIndex = highestBidAt(hash);
      
      require(isValidBidIndex(highestBidIndex), "There are no bids available");
      require(_limitAmount >= minimumAcceptedBid[hash], "limit amount must be at least minimum accepted bid");
        if(bids[hash][highestBidIndex].amount > address(this).balance){
          revert("Contract does not hold enough ether to fulfil the order");
        }
        
        uint256 bidAmount = bids[hash][highestBidIndex].amount;
        require(bidAmount >= _limitAmount, "Limit not reached");
        address winningBidder = bids[hash][highestBidIndex].bidder;
        uint256 fee = Utils.calculatePercentageCents(bidAmount, systemFee());
        uint256 winningAmount = bidAmount.sub(fee);
        
        
        delete bids[hash][highestBidIndex];
        if(payable(msg.sender).send(winningAmount)){
          domain().transferFrom(msg.sender, winningBidder, tokenId);
          
          payable(feeDestination()).transfer(fee);
          
          
          emit BidAccepted(hash, winningBidder, bidAmount, msg.sender, tokenId, winningAmount, fee);
          
        }else{
          revert();
        }
    }
    
    function cancelBid(bytes32 hash) public onlyActiveUser {
      uint256 currentBidIndex = currentBidOfAt(hash, msg.sender);
      if(isValidBidIndex(currentBidIndex)){
        require(bids[hash][currentBidIndex].canCancelAfter < block.timestamp, "Can not be cancelled");
        address payable bidder = payable(bids[hash][currentBidIndex].bidder);
        uint256 amount = bids[hash][currentBidIndex].amount;
        if(amount > 0){
          delete bids[hash][currentBidIndex];
          bidder.transfer(amount);
          emit Refund(hash, bidder, amount);
        }
      }
    }
}
