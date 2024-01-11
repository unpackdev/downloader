// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Unik.sol";
// import "./Auction.sol";

contract UnikMarketplace is Ownable {

  Unik private _Unik;
  // Auction private _Auction;

  struct Art {
    address payable owner;
    uint256 tokenId;
    uint256 price;
  }

  struct Offer{
    address payable buyer;
    address tokenAddress;
    uint256 price;
    uint256 offerId;
    uint256 tokenId;
  }

  struct Auction {
    address payable owner;
    uint initPrice;
    uint startBlock;
    uint endBlock;
    uint256 auctionId;
    // state
    bool canceled;
    uint highestBindingBid;
    address payable highestBidder;
  }

  Offer[] public offers;
  Auction[] public auctions;

  mapping(uint256 => Art) tokenIdToArt;
  mapping(uint256 => Offer[]) tokenIdToOffer;
  mapping(uint256 => Auction) tokenIdToAuction;
  mapping(uint256 => uint256) offerCounts;

  event OfferAdded(address tokenAddress, address buyer, uint256 price, uint256 tokenId, uint256 offerId);
  event artworkSold(address tokenAddress, address from, address to, uint256 price, uint256 tokenId);
  // event priceChanged(address owner, uint256 price, address tokenAddress, uint256 tokenId, uint256 offerId);
  event OfferRemoved(address buyer, uint256 tokenId, uint256 offerId);
  event AuctionCreated(uint256 tokenId, address owner, uint256 auctionId, uint256 price, uint start, uint end);
  event LogBid(uint256 tokenId, address bidder, uint256 price);
  event LogCanceled(uint256 tokenId);
  event ArtSellCreated(address owner, uint256 price, uint256 tokenId);
  event artworkCancel(address owner, uint256 tokenId);


  constructor(address _UnikContractAddress) {
    _setUnikContract(_UnikContractAddress);
    // publisherWallet = _publisherWallet;
  }

  function _setUnikContract(address _UnikContractAddress) private onlyOwner{
    _Unik = Unik(_UnikContractAddress);
  }

  function setOffer(uint256 tokenId, address tokenAddress) public payable{
    // require(_Unik.ownerOf(tokenId) == msg.sender, "Only the owner of the artwork is allowed to do this");
    // require(_Unik.isApprovedForAll(msg.sender, address(this)) == true, "Not approved to sell");
    require(msg.value >= 1000, "Price must be greater than or equal to 1000 wei");

    uint256 offerId = offers.length;
    offerCounts[tokenId] += 1;
    Offer memory offer = Offer(payable(msg.sender), tokenAddress, msg.value, offerId, tokenId);
    // Offer[] memory offerArray = tokenIdToOffer[tokenId];
    // offerArray.push(offer);
    tokenIdToOffer[tokenId].push(offer);
    offers.push(offer);

    emit OfferAdded(address(_Unik), msg.sender, msg.value, tokenId, offerId);
  }

  function createAuction(uint256 price, uint256 tokenId, uint start, uint end) external {
    // require(_Unik.ownerOf(tokenId) == msg.sender, "Only the owner of the artwork is allowed to do this");
    require(start < end, "End date error");
    require(price >= 1000, "Price must be greater than or equal to 1000 wei");
    uint256 auctionId = auctions.length;
    Auction memory auction = Auction(payable(msg.sender), price, start, end, auctionId, false, 0, payable(msg.sender));
    tokenIdToAuction[tokenId] = auction;
    auctions.push(auction);
    uint256 endtime = block.timestamp + end * 24 * 3600;
    emit AuctionCreated(tokenId, msg.sender, auctionId, price, start, endtime);
  }

  function createSellArt(uint256 price, uint256 tokenId) external {
    Art memory art = Art(payable(msg.sender), tokenId, price);
    tokenIdToArt[tokenId] = art;
    offerCounts[tokenId] = 0;
    emit ArtSellCreated(msg.sender, price, tokenId);
  }

  function cancelAuction(uint256 tokenId)
      external
      returns (bool success)
  {
      require (msg.sender == auctions[tokenIdToAuction[tokenId].auctionId].owner, 
                            "Only the owner of the auction is allowed to do this");
      // require (auctions[tokenIdToAuction[tokenId].auctionId].canceled == false, "Already canceled this auction");
      auctions[tokenIdToAuction[tokenId].auctionId].canceled = true;
      tokenIdToAuction[tokenId].canceled = true;
      emit LogCanceled(tokenId);
      return true;
  }

  function placeBid(uint256 tokenId)
        external payable
        returns (bool success)
    {
        // require(msg.sender != auctions[tokenIdToAuction[tokenId].auctionId].owner, "Only buyer is allowed to do this");
        require(auctions[tokenIdToAuction[tokenId].auctionId].canceled == false, "Already canceled this auction");
        // reject payments of 0 ETH
        if(auctions[tokenIdToAuction[tokenId].auctionId].highestBindingBid > 0)
          auctions[tokenIdToAuction[tokenId].auctionId].highestBidder.call{value: auctions[tokenIdToAuction[tokenId].auctionId].highestBindingBid}("");
        
        auctions[tokenIdToAuction[tokenId].auctionId].highestBindingBid = msg.value;
        auctions[tokenIdToAuction[tokenId].auctionId].highestBidder = payable(msg.sender);
        emit LogBid(tokenId, msg.sender, msg.value);
        return true;
    }

  function payAuction(uint256 tokenId, uint256 fee, address tokenAddress, address payable publicAddre)
        public payable
        returns (bool success)
  {
    _Unik.safeTransferFrom(auctions[tokenIdToAuction[tokenId].auctionId].owner, 
                            auctions[tokenIdToAuction[tokenId].auctionId].highestBidder, tokenId);

    _distributeFees(tokenId, auctions[tokenIdToAuction[tokenId].auctionId].highestBindingBid, 
                    auctions[tokenIdToAuction[tokenId].auctionId].owner, fee, publicAddre);
    emit artworkSold(tokenAddress, auctions[tokenIdToAuction[tokenId].auctionId].owner, 
                      auctions[tokenIdToAuction[tokenId].auctionId].highestBidder, 
                      auctions[tokenIdToAuction[tokenId].auctionId].highestBindingBid, tokenId);
    return true;
  }

  // function allAuctions() public returns (Auction[] memory) {
  //   return auctions;
  // }

  function min(uint a, uint b)
        private
        returns (uint)
    {
        if (a < b) return a;
        return b;
    }

  // function changePrice(uint256 newPrice, uint256 tokenId) public{
  //   require(offers[tokenIdToOffer[tokenId].offerId].seller == msg.sender, "Must be seller");
  //   require(newPrice >= 1000, "Price must be greater than or equal to 1000 wei");
  //   // require(offers[tokenIdToOffer[tokenId].offerId].active == true, "Offer must be active");

  //   offers[tokenIdToOffer[tokenId].offerId].price = newPrice;

  //   emit priceChanged(msg.sender, newPrice, tokenAddress, tokenId, offers[tokenIdToOffer[tokenId].offerId].offerId);
  // }

  function removeOffer(uint256 tokenId, uint256 offerId) public{
    require(offers[offerId].buyer == msg.sender, "Must be the seller/owner to remove an offer");
    for (uint i = 0; i < offerCounts[tokenId]; i ++) {
      if(tokenIdToOffer[tokenId][i].offerId == offerId) {
        (bool sent, bytes memory data) 
        = tokenIdToOffer[tokenId][i].buyer.call{value: tokenIdToOffer[tokenId][i].price}("");
        require(sent, "remove offer failed");
        tokenIdToOffer[tokenId][i] = tokenIdToOffer[tokenId][offerCounts[tokenId]];
        tokenIdToOffer[tokenId].pop();
        offerCounts[tokenId] -= 1;
        break;
      }
    }
    emit OfferRemoved(msg.sender, tokenId, offerId);
  }

  function payOffer(uint256 tokenId, uint256 offerId, address tokenAddress, uint256 fee, address payable publicAddre) 
    public 
    payable 
  {
    for( uint i = 0; i < offerCounts[tokenId]; i ++) {
      if( tokenIdToOffer[tokenId][i].offerId != offerId ) {
        (bool sent, bytes memory data) 
        = tokenIdToOffer[tokenId][i].buyer.call{value: tokenIdToOffer[tokenId][i].price}("");
        require(sent, "Failed return offer");
      }
    }
    _Unik.safeTransferFrom(msg.sender, offers[offerId].buyer, tokenId);
    _distributeFees(tokenId, offers[offerId].price, payable(msg.sender), fee, publicAddre);

    delete tokenIdToArt[tokenId];
    delete tokenIdToOffer[tokenId];
    emit artworkSold(tokenAddress, msg.sender, offers[offerId].buyer, offers[offerId].price, tokenId);
  }

  function buyArt(uint256 tokenId, address tokenAddress, uint256 fee, address payable publicAddre) public payable{
    for (uint i = 0; i < offerCounts[tokenId]; i ++)
    {
      (bool sent, bytes memory data) 
      = tokenIdToOffer[tokenId][i].buyer.call{value: tokenIdToOffer[tokenId][i].price}("");
      require(sent, "Falied return offer");
    }

    _Unik.safeTransferFrom(tokenIdToArt[tokenId].owner, msg.sender, tokenId);

    _distributeFees(tokenId, msg.value, tokenIdToArt[tokenId].owner, fee, publicAddre);
    delete tokenIdToOffer[tokenId];
    delete tokenIdToArt[tokenId];

    emit artworkSold(tokenAddress, tokenIdToArt[tokenId].owner, msg.sender, msg.value, tokenId);
  }

  function cancelArt(uint256 tokenId) public payable {
    for (uint i = 0; i < offerCounts[tokenId]; i ++)
    {
      (bool sent, bytes memory data) 
      = tokenIdToOffer[tokenId][i].buyer.call{value: tokenIdToOffer[tokenId][i].price}("");
      require(sent, "Falied return offer");
    }
    delete tokenIdToOffer[tokenId];
    delete tokenIdToArt[tokenId];

    emit artworkCancel(tokenIdToArt[tokenId].owner, tokenId);
  }

  function _computeCreatorFee(uint256 price, uint8 royalty) internal pure returns(uint256){
    uint256 creatorFee = price * royalty / 100;
    return creatorFee;
  }

  function _computePublisherFee(uint256 price, uint256 fee) internal pure returns(uint256){
    uint256 publisherFee = price * fee / 100;
    return publisherFee;
  }

  function _distributeFees(uint256 tokenId, uint256 price, 
    address payable seller, uint256 fee, address payable publisherWallet) 
    internal
  {
    uint8 creatorRoyalty = _Unik.getRoyalty(tokenId);
    uint256 creatorFee = _computeCreatorFee(price, creatorRoyalty);
    uint256 publisherFee = _computePublisherFee(price, fee);
    uint256 payment = price - creatorFee - publisherFee;

    address payable creator = _Unik.getCreator(tokenId);
    creator.call{value: creatorFee}("");
    seller.call{value: payment}("");
    (bool sent, bytes memory data) = publisherWallet.call{value: publisherFee}("");
  }
}
