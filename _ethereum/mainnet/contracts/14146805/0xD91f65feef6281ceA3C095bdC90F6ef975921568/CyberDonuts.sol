// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Libraries.sol";
import "./CanReceiveFunds.sol";

contract CyberDonuts is ERC721Enumerable, CanReceiveFunds, Ownable {
  using Uint256Array for uint256[];
  
  struct Bid {
    address bidder;
    uint256 amount;
    uint256 claimed;
  }
  
  uint256 public maxSupply;
  string private baseUri;
  uint256 public minBid = 0.035 ether;
  uint256 public bidStep = 0.001 ether;
  bool public isAuctionActive;
  uint256 public auctionStarted;
  address public dev;
  uint256 private maxPercentage = 10000;
  uint256 public devShare = 1000;
  
  mapping(uint256=>Bid) bids;

  uint256[] public activeBids;

  mapping(address=>uint256[]) public bidsByUser;
  
  mapping(uint256=>uint256) public adminMints;
  uint256[] public adminMinted;

  string _contractUri;
  
  event BidPlaced(uint256 tokenId, address bidder, uint256 bid, address previousBidder, uint256 previousBid);
  event AuctionEnd();
  event AuctionStart();
  
  modifier onlyDev {
    require(msg.sender == dev, "ND");
    _;
  }
  
  constructor(string memory name_,
              string memory symbol_,
              uint256 maxSupply_,
              uint256 minBid_,
              uint256 bidStep_,
              address dev_)
    ERC721(name_, symbol_) {
    
    maxSupply = maxSupply_;
    dev = dev_;
    minBid = minBid_;
    bidStep = bidStep_;
    
  }

  function setMaxSupply(uint256 maxSupply_) external onlyOwner {
    require(maxSupply_ > maxSupply, "IMS");
    maxSupply = maxSupply_;
  }
  
  function activeBidsCount() external view returns(uint256) {
    return activeBids.length;
  }

  function adminMintedCount() external view returns(uint256) {
    return adminMinted.length;
  }

  function bidsCountOf(address user) external view returns(uint256) {
    return bidsByUser[user].length;
  }

  function bidsOfAt(address user, uint256 index) external view returns(uint256) {
    return bidsByUser[user][index];
  }
  
  function setBaseUri(string memory baseUri_) external onlyOwner {
    baseUri = baseUri_;
  }
  
  function _baseURI() internal view override returns(string memory) {
 
     return baseUri;
     
  }

  function setContractUri(string memory uri) external onlyOwner {
    _contractUri = uri;
  }

  function contractURI() external view returns(string memory) {
    return _contractUri;
  }
  
  function setMinBid(uint256 _amount) external onlyOwner {
    
    minBid = _amount;
    
  }

  function setBidStep(uint256 _amount) external onlyOwner {
    
    require(_amount > 0, "IA");
    bidStep = _amount;
    
  }

  function setDev(address _dev) external onlyDev {
    dev = _dev;
  }

  function startAuction() external onlyOwner {
    require(auctionStarted == 0 && !isAuctionActive);

    auctionStarted = block.timestamp;
    isAuctionActive = true;
    emit AuctionStart();
  }
  
  function stopAuction() external onlyOwner {
    require(auctionStarted > 0 && isAuctionActive, "ANA");
    isAuctionActive = false;
    emit AuctionEnd();
  }

  function buy(uint256 tokenId) external payable {
    
    require(!isAuctionActive && auctionStarted > 0, "AA");
    require(!_exists(tokenId), "TE");
    require(bids[tokenId].amount == 0
            && bids[tokenId].bidder == address(0), "AB");
    require(msg.value >= minBid, "IA");
    require(tokenId >= 1
            && tokenId <= maxSupply, "IT");
    
    _mint(msg.sender, tokenId);
  }

  function bid(uint256 tokenId) external payable {
    require(isAuctionActive, "ANA");
    require(tokenId >= 1
            && tokenId <= maxSupply, "IT");
    require(!_exists(tokenId), "TE");
    
    uint256 minViableBid = minBid;

    if(bids[tokenId].amount > 0){
      minViableBid = bids[tokenId].amount + bidStep;
    }

    uint256 bidAmount = (msg.value / bidStep) * bidStep;

    require(bidAmount >= minViableBid, "IB");

    address prevBidder = bids[tokenId].bidder;
    uint256 prevBid = bids[tokenId].amount;
    
    bids[tokenId].bidder = msg.sender;
    bids[tokenId].amount = msg.value;

    if(prevBid > 0 && address(0) != prevBidder) {
      bidsByUser[prevBidder].remove(tokenId);
      payable(prevBidder).transfer(prevBid);
    } else {
      activeBids.push(tokenId);
    }
    
    if(msg.value > bidAmount){
      payable(msg.sender).transfer(msg.value-bidAmount);
    }
    bidsByUser[msg.sender].insert(tokenId);
    emit BidPlaced(tokenId, msg.sender, bidAmount, prevBidder, prevBid);
  }
  
  function exists(uint256 tokenId) external view returns(bool) {
    
    return _exists(tokenId);
    
  }

  function adminMint(uint256[] calldata tokensIds) external onlyOwner {
    for(uint256 i = 0; i < tokensIds.length; i++){
      uint256 tokenId = tokensIds[i];
      if( !_exists(tokenId)
          && bids[tokenId].amount == 0){
        adminMinted.push(tokenId);
        adminMints[tokenId] = block.timestamp;
        _mint(msg.sender, tokenId);
      }
    }
  }
  
  function highestBid(uint256 tokenId) external view returns(uint256, address){
    return (bids[tokenId].amount, bids[tokenId].bidder);
  }
  
  function claim(uint256 tokenId) external {

    require(auctionStarted > 0 && !isAuctionActive, "AA");
    require(bids[tokenId].bidder == msg.sender
            && bids[tokenId].amount > 0
            && bids[tokenId].claimed == 0, "IC");
    
    bids[tokenId].claimed = block.timestamp;
    _mint(msg.sender, tokenId);
    
  }

  function withdraw() external onlyOwner {
    require(!isAuctionActive, "AA");
    
    uint256 available = address(this).balance;
    require(available > 0, "NB");

    uint256 devPayment = (available * devShare) / maxPercentage;
    
    payable(msg.sender).transfer(available - devPayment);
    
    if(devPayment > 0){
      payable(dev).transfer(devPayment);
    }
    
  }
  
}
