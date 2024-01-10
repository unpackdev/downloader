
interface IAuctionMarketPlace {

    

    // +Event ---------------------------------------------------
    event AuctionCreated(uint256 tokenId, uint256 minBidPrice);
    event AuctionBidSubmitted(uint256 tokenId, uint256 amount, address bidder, bool isFirstBid, uint256 endAt);
    event AuctionFinished(uint256 tokenId, address winner, uint256 amount, address caller);
    event AuctionCanceled(uint256 tokenId);
    event AuctionMinBidPriceChanged(uint256 tokenId, uint256 newMinBidPrice);
    // -Event ---------------------------------------------------

    function createAuction(uint256 _tokenId,  uint256 _minBidPrice) external;
    function placeBid(uint256 _tokenId) payable external;
    function cancelAuction(uint256 _tokenId) external;
    function changeMinBidPrice(uint256 _tokenId,uint256 _minBidPrice) external;
    function settle(uint256 _tokenId) external;

}