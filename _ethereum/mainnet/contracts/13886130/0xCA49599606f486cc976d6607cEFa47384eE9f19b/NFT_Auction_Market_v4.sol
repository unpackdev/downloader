// SPDX-License-Identifier: MIT
pragma solidity >=0.7.5 <0.9.0;
pragma abicoder v2;

import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Math.sol";
import "./Counters.sol";
import "./IERC20.sol";
import "./IERC721.sol";
import "./IERC1155.sol";
import "./ERC1155Receiver.sol";

/**
* Interface for royalties following EIP-2981 (https://eips.ethereum.org/EIPS/eip-2981).
*/
interface IERC2981 is IERC165 {
    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view returns (
        address receiver,
        uint256 royaltyAmount
    );
}

/**
 * @title NFT Auction Market + royalties
 * Sellers can choose a minimum, starting bid, an expiry time when the auction ends
 * Before creating an auction the seller has to approve this contract for the respective token,
 * which will be held in contract until the auction ends.
 * bid price = price + fee 
 * which he will be refunded in case he gets outbid.
 * After the specified expiry date of an auction anyone can trigger the settlement 
 * Not only will we transfer tokens to new owners, but we will also transfer sales money to sellers.
 * All comissions will be credited to the owner / deployer of the marketplace contract.
 */
contract NAMarketV4 is Ownable, ReentrancyGuard, ERC1155Receiver {
  // bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
  bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
  // Protect against overflow
  using SafeMath for uint256;
  // Add math utilities missing in solidity
  using Math for uint256;
  using Counters for Counters.Counter;
  // Number of auctions ever listed
  Counters.Counter public totalAuctionCount;
  // Number of auctions already sold
  Counters.Counter private closedAuctionCount;

  enum TokenType { NONE, ERC721, ERC1155 }
  enum AuctionStatus { NONE, OPEN, CLOSE, SETTLED, CANCELED }
  enum Sort { ASC, DESC, NEW, END, HOT }
  enum BidType { BID, CANCELED }
  
  /* Constructor parameters */
  struct Auction {
      address contractAddress;
      uint256 tokenId;
      uint256 currentPrice;
      uint256 buyNowPrice;
      address seller;
      address highestBidder;
      address ERC20Token;
      string auctionTitle;
      uint256 expiryDate;
      uint256 auctionId;
      AuctionType auctionTypes;
  }

  struct AuctionType {
      uint256 category;
      AuctionStatus status;
      TokenType tokenType;
      uint256 quantity;
  }
  //fee+price
  struct previousInfo {
    uint256 previousPrice;
  }
  //bid
  struct Bid {
        uint256 bidId;
        address bidder;
        uint256 price;
        BidType Type;
        uint256 timestamp;
  }
  struct SellerSale {
    address seller;
    uint256 price;
    uint256 timestamp;
  }

  // minBidSize,minAuctionLiveness, feePercentage
  address public adminAddress; 

  // Minimum amount by which a new bid has to exceed previousBid 0.0001 = 1
  // uint256 public minBidSize = 1;
  /* Minimum duration in seconds for which the auction has to be live
   * timestamp 1h = 3600s
   * default  10m
  */
  uint256 public minAuctionLiveness = 10 * 60;
    
  // //transfer gas
  uint256 public gasSize = 100000;
  address public feeAddress;
  uint256 public feePercentage = 250; // default fee percentage : 2.5%
  uint256 public createAuctionFee = 1000000000000000;// default 0.001

  uint256 public totalMarketVolume;
  uint256 public totalSales;
  //create auction on/off default = true
  bool public marketStatus = true;

  // Save Users credit balances (to be used when they are outbid)
  mapping(address => uint256) public userPriceList;
  mapping(address => mapping(address => uint256)) public userERC20PriceList;
  mapping (address => SellerSale[]) private sellerSales;
  mapping(uint256 => previousInfo) private previousPriceList;
  mapping(uint256 => Auction) public auctions;
  mapping (uint256 => Bid[]) private bidList;
  address[] private uniqSellerList;// Unique seller address
  mapping(address => bool) public blackList;
  uint256[] private recommendAuctionIds;
  
  // EVENTS
  event AuctionCreated(
      uint256 auctionId,
      address contractAddress,
      uint256 tokenId,
      uint256 startingPrice,
      address seller,
      uint256 expiryDate
  );
  event NFTApproved(address nftContract);
  event AuctionCanceled(uint256 auctionId);
  event AuctionSettled(uint256 auctionId, bool sold);
  event BidPlaced(uint256 auctionId, uint256 bidPrice);
  event BidFailed(uint256 auctionId, uint256 bidPrice);
  event UserCredited(address creditAddress, uint256 amount);
  event priceBid(uint256 auctionId, uint256 bidPrice);
  event AdminAuctionCancel(uint256 auctionId, bool feeApproved);
  event CancelBid(uint256 auctionId);
  event RoyaltiesPaid(uint256 tokenId, uint value);


  // MODIFIERS
  modifier onlyAdmin() {
        require(msg.sender == adminAddress, "admin: wut?");
        _;
  }
  
  modifier checkBlackList() {
    if (blackList[msg.sender] == true) {
      require(false, "Blacklist wallet address.");
    }
    _;
  }

  modifier openAuction(uint256 auctionId) {
      require(auctions[auctionId].auctionTypes.status == AuctionStatus.OPEN, "Transaction only open Auctions");
        _;
  }

  modifier settleStatusCheck(uint256 auctionId) {
    AuctionStatus auctionStatus = auctions[auctionId].auctionTypes.status;
      require( auctionStatus != AuctionStatus.SETTLED || 
        auctionStatus != AuctionStatus.CANCELED, "Transaction only open or close Auctions");

      if (auctionStatus == AuctionStatus.OPEN) {
        require(auctions[auctionId].expiryDate < block.timestamp, "Transaction only valid for expired Auctions");
      }
    _;
  }

  modifier nonExpiredAuction(uint256 auctionId) {
      require(auctions[auctionId].expiryDate >= block.timestamp, "Transaction not valid for expired Auctions");
        _;
  }

  modifier onlyExpiredAuction(uint256 auctionId) {
      require(auctions[auctionId].expiryDate < block.timestamp, "Transaction only valid for expired Auctions");
        _;
  }

  modifier noBids(uint256 auctionId) {
      require(auctions[auctionId].highestBidder == address(0), "Auction has bids already");
        _;
  }

  modifier sellerOnly(uint256 auctionId) {
      require(msg.sender == auctions[auctionId].seller, "Caller is not Seller");
        _;
  }

  modifier marketStatusCheck() {
      require(marketStatus, "Market is closed");
        _;
  }

  /**     functions             */
  // Update market status
  function setMarkStatus(bool _marketStatus) public onlyOwner {
        marketStatus = _marketStatus;
  }
  
  // Update only owner 
  function setFeeAddress(address _feeAddress) public onlyOwner {
        require(_feeAddress != address(0), "Invalid Address");
        feeAddress = _feeAddress;
  }
  // Update admin address 
  function setAdmin(address _adminAddress) public onlyOwner {
        adminAddress = _adminAddress;
  }
  // gas update default min 21000
  function setGasSize(uint256 _gasSize) public onlyAdmin {
        gasSize = _gasSize;
  }

  // update blackList 
  //approved true add address 
  function setBlackList(address blackAddress, bool approved) public onlyAdmin {
    blackList[blackAddress] = approved;
  }
  //Recommendation. Auction
  function setRecommendAuctionId(uint256 auctionId, bool approved) public onlyAdmin {
    if (approved) {
      recommendAuctionIds.push(auctionId);
    } else {
      for (uint256 i = 0; i < recommendAuctionIds.length ; i++) {
        if (recommendAuctionIds[i] == auctionId) {
          for (uint j = i; j < recommendAuctionIds.length - 1; j++) {
            recommendAuctionIds[j] = recommendAuctionIds[j + 1];
          }
          recommendAuctionIds.pop();
        }
      }
    }
  }
  // Update minBidSize 
  // function setMinBidSize(uint256 _minBidSize) public onlyAdmin {
  //       minBidSize = _minBidSize;
  // }
  // Update minAuctionLiveness 
  function setMinAuctionLiveness(uint256 _minAuctionLiveness) public onlyAdmin {
        minAuctionLiveness = _minAuctionLiveness;
  }
  // Update Fee percentages 
  function setFeePercentage(uint256 _feePercentage) public onlyAdmin {
        require(_feePercentage <= 10000, "Fee percentages exceed max");
        feePercentage = _feePercentage;
  }
  // Update Fee percentages 
  function setCreateAuctionFee(uint256 _createAuctionFee) public onlyAdmin {
        createAuctionFee = (_createAuctionFee.mul(10**18)).div(1000);
  }

  // Calculate fee due for an auction based on its feePrice
  function calculateFee(uint256 _cuPrice) private view returns(uint256 fee){
      fee  = _cuPrice.mul(feePercentage).div(10000);
  }


  /*
  * AUCTION MANAGEMENT
  * Creates a new auction and transfers the token to the contract to be held in escrow until the end of the auction.
  * Requires this contract to be approved for the token to be auctioned.
  */

  function createAuction(address _contractAddress, uint256 _tokenId, uint256 _startingPrice, string memory auctionTitle,
    uint256 _buyNowPrice, uint256 expiryDate, uint256 _category, TokenType _tokenType, address ERC20Token,
    uint256 _quantity
    ) public payable marketStatusCheck() checkBlackList() nonReentrant 
    returns(uint256 auctionId){
      require(msg.value == createAuctionFee, "The fee amount is different.");
      require(expiryDate.sub(minAuctionLiveness) > block.timestamp, "Expiry date is not far enough in the future");
      require(_tokenType != TokenType.NONE, "Invalid token type provided");
      require(_buyNowPrice > _startingPrice, "Invalid _buyNowPrice");

      uint256 quantity = 1;
      if(_tokenType == TokenType.ERC1155){
        quantity = _quantity;
      }
      // ERC20Token 0x0000000000000000000000000000000000000000
      // Generate Auction Id
      totalAuctionCount.increment();
      auctionId = totalAuctionCount.current();
      // Register new Auction
      auctions[auctionId] = Auction(_contractAddress, _tokenId, _startingPrice, _buyNowPrice, msg.sender,
       address(0), ERC20Token, auctionTitle, expiryDate, auctionId, 
       AuctionType(_category,AuctionStatus.OPEN,  _tokenType, quantity));
      // Transfer Token
      transferToken(auctionId, msg.sender, address(this));
      emit AuctionCreated(auctionId, _contractAddress, _tokenId, _startingPrice, msg.sender, expiryDate);
  }

    //  update auction
  function updateAuction(uint256 auctionId, string memory auctionTitle, uint256 expiryDate,
    uint256 category, TokenType tokenType, AuctionStatus status,
    uint256 quantity) public onlyAdmin  nonReentrant{
    Auction storage auction = auctions[auctionId];
    auction.auctionTitle = auctionTitle;
    auction.expiryDate = expiryDate;
    auction.auctionTypes.category = category;
    auction.auctionTypes.tokenType = tokenType;
    auction.auctionTypes.status = status;
    auction.auctionTypes.quantity = quantity;
  }

  /**
   * Cancels an auction and returns the token to the original owner.
   * Requires the caller to be the seller who created the auction, the auction to be open and no bids having been placed on it.
   */
  function cancelAuction(uint256 auctionId) public openAuction(auctionId) noBids(auctionId) sellerOnly(auctionId) nonReentrant{
      auctions[auctionId].auctionTypes.status = AuctionStatus.CANCELED;
      closedAuctionCount.increment();
      transferToken(auctionId, address(this), msg.sender);
      emit AuctionCanceled(auctionId);
  }

  /**
   * Settles an auction.
   * If at least one bid has been placed the token will be transfered to its new owner, the seller will be credited the sale price
   * and the contract owner will be credited the fee.
   * If no bid has been placed on the token it will just be transfered back to its original owner.
   */
  function settleAuction(uint256 auctionId) public settleStatusCheck(auctionId) nonReentrant{
      Auction storage auction = auctions[auctionId];
      auction.auctionTypes.status = AuctionStatus.SETTLED;
      closedAuctionCount.increment();
      
      bool sold = auction.highestBidder != address(0);
      if(sold){
        // If token was sold transfer it to its new owner and credit seller / contractOwner with price / fee
        transferToken(auctionId, address(this), auction.highestBidder);
        uint256 cuPrice = 0;
        // NFT royalties
		    if (_checkRoyalties(auction.contractAddress)) {
            (address royaltiesReceiver, uint256 royaltiesAmount) = IERC2981(auction.contractAddress).royaltyInfo(auction.tokenId, auction.currentPrice);
            if (auction.seller != royaltiesReceiver) {
			        cuPrice = auction.currentPrice - royaltiesAmount;
            } else {
              cuPrice = auction.currentPrice;
            }
            if (royaltiesAmount > 0) {
                if (_isERC20Auction(auction.ERC20Token)) {
                    creditUserToken(royaltiesReceiver, auction.ERC20Token, royaltiesAmount);
                } else {
                    creditUser(royaltiesReceiver, royaltiesAmount);
                }
            } 
            emit RoyaltiesPaid(auction.tokenId, royaltiesAmount);
        }
        if (_isERC20Auction(auction.ERC20Token)) {
          creditUserToken(auction.seller, auction.ERC20Token, cuPrice);
          creditUserToken(feeAddress, auction.ERC20Token, calculateFee(auction.currentPrice));
        } else {
          creditUser(auction.seller, cuPrice); 
          creditUser(feeAddress, calculateFee(auction.currentPrice));
        }

        saveSales(auction.seller, auction.currentPrice);
        totalSales = totalSales.add(auction.currentPrice);
      } else {
        // If token was not sold, return ownership to the seller
        transferToken(auctionId, address(this), auction.seller);
      }
      emit AuctionSettled(auctionId, sold);
  }
  //Save sales information
  function saveSales(address sellerAddress, uint256 price) private {
    if (uniqSellerList.length == 0) {
      uniqSellerList.push(sellerAddress);
    } else {
      bool chkSeller = false;
      for (uint256 i = 0; i < uniqSellerList.length; i++) {
        if (uniqSellerList[i] == sellerAddress) {
          chkSeller = true;
        }
      }
      if (!chkSeller) {
        uniqSellerList.push(sellerAddress);
      }
    }
    SellerSale memory sellerInfo = SellerSale(sellerAddress, price, block.timestamp);
    sellerSales[sellerAddress].push(sellerInfo);
  }

    /**
	 * Checks if a contract supports EIP-2981 for royalties.
	 * View EIP-165 (https://eips.ethereum.org/EIPS/eip-165).
	 */
	function _checkRoyalties(address _contract) internal view returns (bool) {
        (bool success) = IERC165(_contract).supportsInterface(_INTERFACE_ID_ERC2981);
		return success;
    }

  /**
   * Credit user with given amount in ETH
   * Credits a user with a given amount that he can later withdraw from the contract.
   * Used to refund outbidden buyers and credit sellers / contract owner upon sucessfull sale.
   */
  function creditUser(address creditAddress, uint256 amount) private {
      userPriceList[creditAddress] = userPriceList[creditAddress].add(amount);
      emit UserCredited(creditAddress, amount);
  }
  function creditUserToken(address creditAddress, address tokenAddress, uint256 amount) private {
      userERC20PriceList[creditAddress][tokenAddress] = userERC20PriceList[creditAddress][tokenAddress].add(amount);
      emit UserCredited(creditAddress, amount);
  }

  /**
   *  Withdraws all credit of the caller
   * Transfers all of his credit to the caller and sets the balance to 0
   * Fails if caller has no credit.
   */
  function withdrawCredit() public nonReentrant{
      uint256 creditBalance = userPriceList[msg.sender];
      require(creditBalance > 0, "User has no credits to withdraw");
      userPriceList[msg.sender] = 0;

      (bool success, ) = msg.sender.call{value: creditBalance}("");
      require(success);
  }

  function withdrawToken(address tokenAddress) public nonReentrant{
    uint256 creditBalance = userERC20PriceList[msg.sender][tokenAddress];
    require(creditBalance > 0, "User has no credits to withdraw");
    userERC20PriceList[msg.sender][tokenAddress] = 0;

    IERC20(tokenAddress).transfer(msg.sender, creditBalance);
  }

  /**
   * Places a bid on the selected auction at the selected price
   * Requires the provided bid price to exceed the current highest bid by at least the minBidSize.
   * Also requires the caller to transfer the exact amount of the chosen bidPrice plus fee, to be held in escrow by the contract
   * until the auction is settled or a higher bid is placed.
   */
  function placeBid(uint256 auctionId, uint256 bidPrice) public payable openAuction(auctionId) nonExpiredAuction(auctionId) nonReentrant{
      Auction storage auction = auctions[auctionId];
      // require(bidPrice >= auction.currentPrice.add((minBidSize.mul(10**18)/10000)), "Bid has to exceed current price by the minBidSize or more");
      require(bidPrice > auction.currentPrice, "It should be higher than the current bid amount");

      if (_isERC20Auction(auction.ERC20Token)) {
        require(msg.value == 0, "msg.value must be zero.");
        _payout(auction.ERC20Token, msg.sender, bidPrice);
      } else {
        require(msg.value == bidPrice.add(calculateFee(bidPrice)), "The payment amount and the bid amount are different");
      }

      emit priceBid(auctionId, bidPrice);

      uint256 creditAmount;
      // If this is not the first bid, credit the previous highest bidder
      address previousBidder = auction.highestBidder;
    
      if (auction.buyNowPrice <= bidPrice) {
        if (auction.auctionTypes.tokenType == TokenType.ERC721) {
          auction.auctionTypes.status = AuctionStatus.CLOSE;
        } else if (auction.auctionTypes.tokenType == TokenType.ERC1155){
          if (auction.auctionTypes.quantity == 0) {
            auction.auctionTypes.status = AuctionStatus.CLOSE;
          } else {
            auction.auctionTypes.quantity--;
          }
        }
      }

      //bid list 
      uint256 newBidId = bidList[auctionId].length + 1;
      Bid memory newBid = Bid(newBidId, msg.sender, bidPrice, BidType.BID, block.timestamp);
      bidList[auctionId].push(newBid);

      //bid refund
      if(previousBidder != address(0)){
        creditAmount = previousPriceList[auctionId].previousPrice;
        if (_isERC20Auction(auction.ERC20Token)) {
          creditUserToken(previousBidder, auction.ERC20Token, creditAmount);
        } else {
          creditUser(previousBidder, creditAmount);
        }
      }
    
      previousPriceList[auctionId].previousPrice = bidPrice.add(calculateFee(bidPrice));

      auction.highestBidder = msg.sender;
      auction.currentPrice = bidPrice;

  }

  function _payout(
        address ERC20Token,
        address bidder,
        uint256 bidPrice
    ) internal {
        uint256 newBidPrice = bidPrice.add(calculateFee(bidPrice));
            bool sent = IERC20(ERC20Token).transferFrom(bidder, address(this), newBidPrice);
            require(sent, "transfer fail");
  }

    function _isERC20Auction(address _auctionERC20Token)
        internal
        pure
        returns (bool)
    {
        return _auctionERC20Token != address(0);
    }

  /**
   * Transfer the token(s) belonging to a given auction.
   * Supports both ERC721 and ERC1155 tokens
   */
  function transferToken(uint256 auctionId, address from, address to) private {
      require(to != address(0), "Cannot transfer token to zero address");

      Auction storage auction = auctions[auctionId];
      require(auction.auctionTypes.status != AuctionStatus.NONE, "Cannot transfer token of non existent auction");

      TokenType tokenType = auction.auctionTypes.tokenType;
      uint256 tokenId = auction.tokenId;
      address contractAddress = auction.contractAddress;

      if(tokenType == TokenType.ERC721){
        IERC721(contractAddress).transferFrom(from, to, tokenId);
      }
      else if(tokenType == TokenType.ERC1155){
        uint256 quantity = auction.auctionTypes.quantity;
        require(quantity > 0, "Cannot transfer 0 quantity of ERC1155 tokens");
        IERC1155(contractAddress).safeTransferFrom(from, to, tokenId, quantity, "");
      }
      else{
        revert("Invalid token type for transfer");
      }
  }
  //cancel auction
  function adminCancelAuction(uint256 auctionId, bool feeApproved) public openAuction(auctionId) onlyAdmin  nonReentrant{
    Auction storage auction = auctions[auctionId];
    address previousBidder = auction.highestBidder;
    uint256 creditAmount = 0;
    //bid refund
    if(previousBidder != address(0)){
      if (feeApproved) {
        creditAmount = auction.currentPrice; //only price, Cancellation fee.
      } else {
        creditAmount = previousPriceList[auctionId].previousPrice; //fee+ price
      }
      if (_isERC20Auction(auction.ERC20Token)) {
          creditUserToken(previousBidder, auction.ERC20Token, creditAmount);
      } else {
        creditUser(previousBidder, creditAmount);
      }
    }
    auction.auctionTypes.status = AuctionStatus.CANCELED;
  
    emit AdminAuctionCancel(auctionId, feeApproved);
  }
  //cancel bid
  function cancelBid(uint256 auctionId) public openAuction(auctionId) nonExpiredAuction(auctionId) nonReentrant {
    Auction storage auction = auctions[auctionId];
    require(msg.sender == auction.highestBidder, "Invalid Request");
    address previousBidder = auction.highestBidder;
    uint256 creditAmount = 0;
    //bid refund
    if(previousBidder != address(0)){
      creditAmount = auction.currentPrice; //only price, Cancellation fee.
      if (_isERC20Auction(auction.ERC20Token)) {
          creditUserToken(previousBidder, auction.ERC20Token, creditAmount);
      } else {
        creditUser(previousBidder, creditAmount);
      }
    }
    uint256 newBidId = bidList[auctionId].length + 1;
    Bid memory newBid = Bid(newBidId, msg.sender, auction.currentPrice, BidType.BID, block.timestamp);
    bidList[auctionId].push(newBid);
    
    auction.highestBidder = address(0);
    previousPriceList[auctionId].previousPrice = 0;
  
    emit CancelBid(auctionId);
  }


  //data func auction list 
  function getOpenAuctions(uint256 category, Sort sort, string memory keyword, 
  uint256 offset, uint256 limit) public view returns 
  (Auction[] memory, uint256, uint256) {
        uint256 totalLen = totalAuctionCount.current();
        Auction[] memory values = new Auction[] (totalLen);
        uint256 resultLen = 0;
        bytes memory checkString = bytes(keyword);

        //auctionId is no zero.
        //auction open, type count
        for (uint256 i = 1; i <= totalLen; i++) {
          if(auctions[i].auctionTypes.status == AuctionStatus.OPEN){
            values[resultLen] = auctions[i];
            resultLen++;
          }  
        }
        resultLen = 0;
        if (checkString.length > 0) {
          values = sfilter(values, category, keyword);
        } else if (category != 0) {
          values = cfilter(values, category);
        }

        for (uint256 i = 0; i < values.length; i++) {
          if(values[i].seller != address(0)){
            resultLen++;
          }  
        }

        Auction[] memory result = new Auction[](resultLen);
        uint256 rId = 0;
        for (uint256 i = 0; i < values.length; i++) {
          if(values[i].seller != address(0)){
            result[rId] = values[i];
            rId++;
          }  
        }
        //sort
        result = sortMap(result, resultLen, sort);


        if(limit == 0) {
            limit = 1;
        }
        
        if (limit > resultLen - offset) {
            limit = 0 > resultLen - offset ? 0 : resultLen - offset;
        }
       
        Auction[] memory newAuctions = new Auction[] (result.length > limit ? limit: result.length);

        if (result.length > limit) {
          for (uint256 i = 0; i < limit; i++) {
            newAuctions[i] = result[offset+i];
          }
          return (newAuctions, offset + limit, resultLen);
        } else {
          return (result, offset + limit, resultLen);
        }
        
  }

  //seller open auction list
  function getSellerAuctions(address sellerAddress, Sort sort, uint256 offset, uint256 limit) public view returns 
  (Auction[] memory, uint256, uint256) {
        uint256 totalLen = totalAuctionCount.current();
        Auction[] memory values = new Auction[] (totalLen);
        uint256 resultLen = 0;

        //auctionId is no zero.
        //auction open, type count
        for (uint256 i = 1; i <= totalLen; i++) {
          if(auctions[i].auctionTypes.status == AuctionStatus.OPEN
            && auctions[i].seller == sellerAddress){
            values[resultLen] = auctions[i];
            resultLen++;
          }  
        }

        //sort
        values = sortMap(values, resultLen, sort);

        if(limit == 0) {
            limit = 1;
        }
        
        if (limit > resultLen - offset) {
            limit = 0 > resultLen - offset ? 0 : resultLen - offset;
        }
       
        Auction[] memory newAuctions = new Auction[] (resultLen > limit ? limit: resultLen);

        if (resultLen > limit) {
          for (uint256 i = 0; i < limit; i++) {
            newAuctions[i] = values[offset+i];
          }
          return (newAuctions, offset + limit, resultLen);
        } else {
          return (values, offset + limit, resultLen);
        }
        
  }
 
  //Recommendation Auction
  function getRecommendationAuctions() public view returns (Auction[] memory, uint256) {
    uint256 totalLen = recommendAuctionIds.length;
    Auction[] memory values = new Auction[] (totalLen);
    uint256 resultLen = 0;

    //auctionId is no zero.
    //auction open, type count
    for (uint256 i = 0; i < totalLen; i++) {
      if(auctions[recommendAuctionIds[i]].auctionTypes.status == AuctionStatus.OPEN) {
        values[resultLen] = auctions[i];
        resultLen++;
      }  
    }
    return (values, resultLen);
  }
  //bids
  function getBids(uint256 auctionId) public view returns(Bid[] memory){
      return bidList[auctionId];
  }

  function getUserAuctions(address seller) public view returns(Auction[] memory) {
    uint256 resultCount = 0;

    for(uint256 i = 1; i <= totalAuctionCount.current(); i++) {
      if (auctions[i].seller == seller) {
        resultCount++;
      }
    }
    Auction[] memory values = new Auction[] (resultCount);
    uint256 rInt = 0;
    for(uint256 i = 1; i <= totalAuctionCount.current(); i++) {
      if (auctions[i].seller == seller) {
        values[rInt] = auctions[i];
        rInt++;
      }
    }
    return values;
  }
  function getUserBidAuctions(address seller) public view returns(Auction[] memory) {
    uint256 resultCount = 0;

    for(uint256 i = 1; i <= totalAuctionCount.current(); i++) {
      if (auctions[i].highestBidder == seller) {
        resultCount++;
      }
    }
    Auction[] memory values = new Auction[] (resultCount);
    uint256 rInt = 0;
    for(uint256 i = 1; i <= totalAuctionCount.current(); i++) {
      if (auctions[i].highestBidder == seller) {
        values[rInt] = auctions[i];
        rInt++;
      }
    }
    return values;
  }
  //Filter based on the timestamp.
  function getSellerSalesList(uint256 timestamp) public view returns(SellerSale[] memory) {
    SellerSale[] memory topSellerList = new SellerSale[](uniqSellerList.length);
    SellerSale memory cuSellerSales;
    for(uint256 i = 0; i < uniqSellerList.length; i++) {
      cuSellerSales.seller = uniqSellerList[i];
      cuSellerSales.price = 0;
      cuSellerSales.timestamp = timestamp;
      for(uint256 j = 0; j < sellerSales[uniqSellerList[i]].length; j++) {
        if (timestamp <= sellerSales[uniqSellerList[i]][j].timestamp) {
          cuSellerSales.price = cuSellerSales.price.add(sellerSales[uniqSellerList[i]][j].price);
        }
      }
      topSellerList[i] = cuSellerSales;
    }
    return topSellerList;
  }
  //string substring
  function substring(string memory str, uint256 startIndex, uint256 endIndex) private pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex-startIndex);
        for(uint256 i = startIndex; i < endIndex; i++) {
            result[i-startIndex] = strBytes[i];
        }
        return string(result);
  }

  /* filter */
  function sfilter(Auction[] memory values, uint256 category, string memory keyword) 
    private pure returns (Auction[] memory) {
    Auction[] memory sValues = new Auction[](values.length);

    bytes memory kBytes = bytes(keyword);
    for (uint256 i = 0; i < values.length; i ++) {
      bytes memory tBytes = bytes(values[i].auctionTitle);
      for (uint256 j = 0; j < tBytes.length; j ++) {

          if(keccak256(abi.encodePacked(substring(values[i].auctionTitle, j, 
          tBytes.length < j+kBytes.length ? tBytes.length : j+kBytes.length))) 
            == keccak256(abi.encodePacked(keyword))) {
              sValues[i] = values[i];
              break;
          }
      }
    }
    sValues = cfilter(sValues, category);
    return sValues;

  }

  function cfilter(Auction[] memory values, uint256 category) private pure returns (Auction[] memory) {
    Auction[] memory cValues = new Auction[](values.length);
    if (category != 0) {
      for (uint256 i = 0; i < values.length; i++) {
        if(values[i].auctionTypes.category == category){
          cValues[i] = values[i];
        } 
      }
      return cValues;
    } else {
      return values;
    }
  }

  /*  sort  */
  function sortMap(Auction[] memory arr, uint256 limit, Sort sort) private view returns (Auction[] memory) {
    //sort
    Auction memory temp;
    for(uint256 i = 0; i < limit; i++) {
        for(uint256 j = i+1; j < limit ;j++) {
          if (sort == Sort.NEW) {
            if(arr[i].expiryDate > arr[j].expiryDate) {
                temp = arr[i];
                arr[i] = arr[j];
                arr[j] = temp;
            }
          } else if (sort == Sort.END) {
            if(arr[i].expiryDate < arr[j].expiryDate) {
                temp = arr[i];
                arr[i] = arr[j];
                arr[j] = temp;
            }
          } else if (sort == Sort.ASC) {
            if(arr[i].currentPrice > arr[j].currentPrice) {
                temp = arr[i];
                arr[i] = arr[j];
                arr[j] = temp;
            }
          } else if (sort == Sort.HOT) {
            if( bidList[arr[i].auctionId].length < bidList[arr[j].auctionId].length) {
                temp = arr[i];
                arr[i] = arr[j];
                arr[j] = temp;
            }
          } else {
            if(arr[i].currentPrice < arr[j].currentPrice) {
                temp = arr[i];
                arr[i] = arr[j];
                arr[j] = temp;
            }
          } 
        }
    }
    return arr;
  }

}