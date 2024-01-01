// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

import "./IERC721.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";
import "./IERC1155.sol";
import "./SafeERC20.sol";
import "./ERC1155Holder.sol";
import "./IERC2981.sol";
import "./IERC165.sol";
import "./ILoveNFTMarketplace.sol";
import "./ILoveNFTShared.sol";
import "./LoveRoles.sol";
import "./TokenIdentifiers.sol";

/* Love NFT Marketplace
    List NFT,
    Buy NFT,
    Offer NFT,
    Accept offer,
    Create auction,
    Bid place,
    & support Royalty
*/
contract LoveNFTMarketplace is ILoveNFTMarketplace, LoveRoles, ERC1155Holder, ReentrancyGuard {
  using TokenIdentifiers for uint256;
  using SafeERC20 for IERC20;

  uint256 public platformFee = 50;
  uint256 public constant LISTING_FEE = 1 ether;
  uint256 public constant MINIMUM_BUYING_FEE = 5 ether;
  uint256 public reservedBalance;
  address public feeReceiver;
  ILoveNFTShared private immutable loveNFTShared;
  IERC20 private immutable loveToken;

  constructor(address _loveToken, address _loveNFTShared, address tokenOwner) {
    transferOwnership(tokenOwner);
    loveToken = IERC20(_loveToken);
    loveNFTShared = ILoveNFTShared(_loveNFTShared);
  }

  // NFT => list struct
  mapping(bytes32 encodedNft => ListNFT listingStruct) private listNfts;

  // NFT => offerer address => offer price => offer struct
  mapping(bytes32 encodedNft => mapping(address offerer => mapping(uint256 price => OfferNFT offerStruct)))
    private offerNfts;

  // NFT => action struct
  mapping(bytes32 encodedNft => AuctionNFT auctionStruct) private auctionNfts;

  modifier onlyListedNFT(NFT calldata nft) {
    ListNFT memory listedNFT = listNfts[encodeNft(nft)];
    require(
      listedNFT.seller != address(0) && listedNFT.price > 0 && block.timestamp <= listedNFT.endTime,
      'not listed'
    );
    _;
  }

  modifier onAuction(NFT calldata nft) {
    NFT memory auctionNft = auctionNfts[encodeNft(nft)].nft;
    require(auctionNft.addr == nft.addr && auctionNft.tokenId == nft.tokenId, 'auction is not created');
    _;
  }

  modifier notOnAuction(NFT calldata nft) {
    AuctionNFT memory auction = auctionNfts[encodeNft(nft)];
    require(auction.nft.addr == address(0) || auction.success, 'auction already created');
    _;
  }

  modifier onlyOfferedNFT(OfferNFTParams calldata params) {
    OfferNFT memory offer = offerNfts[encodeNft(params.nft)][params.offerer][params.price];
    require(offer.offerer == params.offerer && offer.offerPrice == params.price, 'not offered');
    require(!offer.accepted, 'already accepted');
    _;
  }

  modifier minimumPrice(uint256 price) {
    require(price > MINIMUM_BUYING_FEE, 'price is less than the minimum commission');
    _;
  }

  /**
   * @notice List NFT on Marketplace
   * @param params The listing parameters (nft, tokenId, price, startTime, endTime)
   */
  function listNft(ListingParams calldata params) external minimumPrice(params.price) returns (uint256) {
    require(block.timestamp <= params.startTime && params.endTime > params.startTime, 'invalid time range');

    bytes32 encodedNft = encodeNft(params.nft);
    ListNFT memory listedNFT = listNfts[encodedNft];
    TokenType tokenType = _getTokenType(params.nft.addr);
    // If the NFT is already listed, the seller must be the same as the caller.
    if (listedNFT.seller != address(0)) {
      require(listedNFT.seller == msg.sender, 'not seller');
    } else {
      // Otherwise, the caller must be the owner of the NFT.
      _verifyOwnershipAndApproval(msg.sender, params.nft, tokenType);
      // The caller must have enough tokens for the platform fee.
      require(loveToken.balanceOf(msg.sender) >= LISTING_FEE, 'no tokens for platform fee');
      // The caller must transfer the NFT to the marketplace contract.
      _transferNFT(msg.sender, address(this), params.nft, tokenType);
      // The caller must transfer the platform fee to the marketplace contract.
      loveToken.safeTransferFrom(msg.sender, address(this), LISTING_FEE);
    }

    // Update the listing.
    listNfts[encodedNft] = ListNFT({
      nft: params.nft,
      tokenType: tokenType,
      price: params.price,
      seller: msg.sender,
      startTime: params.startTime,
      endTime: params.endTime
    });
    emit ListedNFT(params.nft.addr, params.nft.tokenId, params.price, msg.sender, params.startTime, params.endTime);
    return LISTING_FEE;
  }

  function getListedNFT(NFT calldata nft) external view returns (ListNFT memory) {
    return listNfts[encodeNft(nft)];
  }

  /**
   * @notice Cancel listed NFT
   * @param nft NFT address
   */
  function cancelListedNFT(NFT calldata nft) external onlyListedNFT(nft) {
    bytes32 encodedNft = encodeNft(nft);
    ListNFT memory listedNFT = listNfts[encodedNft];
    // Ensure the sender is the seller
    require(listedNFT.seller == msg.sender, 'not seller');

    delete listNfts[encodedNft];
    // Transfer the NFT back to the seller
    _transferNFT(address(this), msg.sender, nft, listedNFT.tokenType);

    emit CanceledListedNFT(
      listedNFT.nft.addr,
      listedNFT.nft.tokenId,
      listedNFT.price,
      listedNFT.seller,
      listedNFT.startTime,
      listedNFT.endTime
    );
  }

  function buyLazyListedNFT(
    ILoveNFTShared.MintRequest calldata params,
    bytes calldata signature
  ) external returns (uint256 priceWithRoyalty) {
    address creator = params.tokenId.tokenCreator();

    // calculate platform fee
    (uint256 amount, ) = calculateFeeAndAmount(params.price);
    // calculate royalty fee

    uint256 royaltyAmount = (params.price * params.royaltyFraction) / loveNFTShared.feeDenominator();

    TokenRoyaltyInfo memory royaltyInfo = TokenRoyaltyInfo(params.royaltyRecipient, royaltyAmount);

    loveToken.safeTransferFrom(msg.sender, address(this), params.price + royaltyInfo.royaltyAmount);

    if (royaltyInfo.royaltyReceiver == creator) {
      uint256 amountWithRoyalty = amount + royaltyInfo.royaltyAmount;
      loveToken.safeTransfer(creator, amountWithRoyalty);
    } else {
      _transferRoyalty(royaltyInfo, address(this));
      loveToken.safeTransfer(creator, amount);
    }

    // mint nft
    loveNFTShared.redeem(msg.sender, params, signature);

    emit BoughtNFT(address(loveNFTShared), params.tokenId, params.price, creator, msg.sender);

    return royaltyInfo.royaltyAmount + params.price;
  }

  /**
   * @notice Buy NFT on Marketplace
   * @param nft NFT address
   * @param price listed price
   * @return priceWithRoyalty price with fees
   */
  function buyNFT(NFT calldata nft, uint256 price) external onlyListedNFT(nft) returns (uint256 priceWithRoyalty) {
    bytes32 encodedNft = encodeNft(nft);
    ListNFT memory listedNft = listNfts[encodedNft];
    require(price >= listedNft.price, 'less than listed price');

    delete listNfts[encodedNft];
    TokenRoyaltyInfo memory royaltyInfo = _tryGetRoyaltyInfo(nft, price);
    _transferRoyalty(royaltyInfo, msg.sender);
    // remove nft from listing
    (uint256 amount, uint256 buyingFee) = calculateFeeAndAmount(price);
    // transfer platform fee to marketplace contract
    loveToken.safeTransferFrom(msg.sender, address(this), buyingFee);

    // Transfer payment to nft owner
    loveToken.safeTransferFrom(msg.sender, listedNft.seller, amount);

    // Transfer NFT to buyer
    _transferNFT(address(this), msg.sender, nft, listedNft.tokenType);

    emit BoughtNFT(nft.addr, nft.tokenId, price, listedNft.seller, msg.sender);
    return price + royaltyInfo.royaltyAmount;
  }

  /**
   * @notice Offer NFT on Marketplace
   * @param params OfferNFTParams
   * @return offerPriceWithRoyalty offer price with royalty
   */
  function offerNFT(
    OfferNFTParams calldata params
  ) external notOnAuction(params.nft) minimumPrice(params.price) returns (uint256) {
    // nft should be minted
    TokenType tokenType = _getTokenType(params.nft.addr);
    if (tokenType == TokenType.ERC721) {
      require(IERC721(params.nft.addr).ownerOf(params.nft.tokenId) != address(0), 'not exist');
    } else if (params.nft.addr == address(loveNFTShared)) {
      require(loveNFTShared.exists(params.nft.tokenId), 'not exist');
    }

    TokenRoyaltyInfo memory royaltyInfo = _tryGetRoyaltyInfo(params.nft, params.price);
    uint256 offerPriceWithRoyalty = params.price + royaltyInfo.royaltyAmount;

    reservedBalance += offerPriceWithRoyalty;

    loveToken.safeTransferFrom(msg.sender, address(this), offerPriceWithRoyalty);

    offerNfts[encodeNft(params.nft)][msg.sender][params.price] = OfferNFT({
      nft: params.nft,
      tokenType: tokenType,
      offerer: msg.sender,
      offerPrice: params.price,
      accepted: false,
      royaltyInfo: royaltyInfo
    });

    emit OfferedNFT(params.nft.addr, params.nft.tokenId, params.price, msg.sender);
    return offerPriceWithRoyalty;
  }

  /**
   * @notice Cancel offer
   * @param params The offer parameters (nft, tokenId, offerer, price)
   * @return offerPriceWithRoyalty offer price with royalty
   */
  function cancelOfferNFT(OfferNFTParams calldata params) external onlyOfferedNFT(params) returns (uint256) {
    require(params.offerer == msg.sender, 'not offerer');

    bytes32 encodedNft = encodeNft(params.nft);
    OfferNFT memory offer = offerNfts[encodedNft][params.offerer][params.price];
    delete offerNfts[encodedNft][params.offerer][params.price];

    uint256 offerPriceWithRoyalty = offer.offerPrice + offer.royaltyInfo.royaltyAmount;
    reservedBalance -= offerPriceWithRoyalty;

    loveToken.safeTransfer(offer.offerer, offerPriceWithRoyalty);

    emit CanceledOfferedNFT(offer.nft.addr, offer.nft.tokenId, offer.offerPrice, params.offerer);
    return offerPriceWithRoyalty;
  }

  /**
   * @notice Accept offer
   * @param params The offer parameters (nft, tokenId, offerer, price)
   * @return amount amount transfer to seller
   */
  function acceptOfferNFT(
    OfferNFTParams calldata params
  ) external onlyOfferedNFT(params) nonReentrant returns (uint256) {
    bytes32 encodedNft = encodeNft(params.nft);
    OfferNFT storage offer = offerNfts[encodedNft][params.offerer][params.price];
    ListNFT memory list = listNfts[encodedNft];
    address from = address(this);
    // If the NFT is listed, the seller is the owner of the NFT
    if (list.seller != address(0)) {
      require(msg.sender == list.seller, 'not listed owner');
      delete listNfts[encodedNft];
    } else {
      // If not, the seller is the owner of the NFT
      _verifyOwnershipAndApproval(msg.sender, params.nft, offer.tokenType);
      from = msg.sender;
    }

    TokenRoyaltyInfo memory royaltyInfo = offer.royaltyInfo;
    uint256 offerPriceWithRoyalty = params.price + royaltyInfo.royaltyAmount;

    // Release reserved balance
    reservedBalance -= offerPriceWithRoyalty;
    offer.accepted = true;

    // Calculate & Transfer platform fee
    (uint256 amount, ) = calculateFeeAndAmount(params.price);

    if (royaltyInfo.royaltyReceiver == msg.sender) {
      uint256 amountWithRoyalty = amount + royaltyInfo.royaltyAmount;
      loveToken.safeTransfer(msg.sender, amountWithRoyalty);
    } else {
      _transferRoyalty(royaltyInfo, address(this));
      loveToken.safeTransfer(msg.sender, amount);
    }

    // Transfer NFT to offerer
    _transferNFT(from, params.offerer, params.nft, offer.tokenType);

    emit AcceptedNFT(params.nft.addr, params.nft.tokenId, params.price, params.offerer, msg.sender);
    return amount;
  }

  /**
   * @notice Create auction for NFT
   * @dev This function allows users to create an auction for an NFT
   * @param params The auction parameters (nft, tokenId, initialPrice, minBidStep, startTime, endTime)
   */
  function createAuction(
    AuctionParams calldata params
  ) external notOnAuction(params.nft) minimumPrice(params.initialPrice) {
    TokenType tokenType = _getTokenType(params.nft.addr);
    // Verify if the caller is the owner of the NFT
    _verifyOwnershipAndApproval(msg.sender, params.nft, tokenType);

    require(loveToken.balanceOf(msg.sender) >= LISTING_FEE, 'no tokens for platform fee');
    // The caller must transfer the platform fee to the marketplace contract.
    loveToken.safeTransferFrom(msg.sender, address(this), LISTING_FEE);
    // Transfer the NFT from the caller to the contract
    _transferNFT(msg.sender, address(this), params.nft, tokenType);

    // Store the auction details in the auctionNfts mapping
    auctionNfts[encodeNft(params.nft)] = AuctionNFT({
      nft: params.nft,
      tokenType: tokenType,
      creator: msg.sender,
      initialPrice: params.initialPrice,
      minBidStep: params.minBidStep,
      startTime: params.startTime,
      endTime: params.endTime,
      lastBidder: address(0),
      highestBid: params.initialPrice,
      royaltyInfo: TokenRoyaltyInfo(address(0), 0),
      winner: address(0),
      success: false
    });

    emit CreatedAuction(
      params.nft.addr,
      params.nft.tokenId,
      params.initialPrice,
      params.minBidStep,
      params.startTime,
      params.endTime,
      msg.sender
    );
  }

  /**
   * @notice Cancel auction
   * @param nft NFT address
   */
  function cancelAuction(NFT calldata nft) external onAuction(nft) {
    bytes32 encodedNft = encodeNft(nft);
    AuctionNFT memory auction = auctionNfts[encodedNft];
    require(auction.creator == msg.sender, 'not auction creator');
    require(!auction.success, 'auction already success');
    require(auction.lastBidder == address(0), 'already have bidder');

    delete auctionNfts[encodedNft];

    _transferNFT(address(this), msg.sender, nft, auction.tokenType);

    emit CanceledAuction(nft.addr, nft.tokenId);
  }

  /**
   * @notice Place bid on auction
   * @param nft NFT address
   * @param bidPrice bid price (must be greater than highest bid + min bid step)
   * @return bidPriceWithRoyalty bid price with royalty
   */
  function bidPlace(NFT calldata nft, uint256 bidPrice) external onAuction(nft) nonReentrant returns (uint256) {
    AuctionNFT storage auction = auctionNfts[encodeNft(nft)];
    require(block.timestamp >= auction.startTime, 'auction not started');
    require(block.timestamp <= auction.endTime, 'auction ended');
    require(bidPrice >= auction.highestBid + auction.minBidStep, 'less than min bid price');

    TokenRoyaltyInfo memory royaltyInfo = _tryGetRoyaltyInfo(nft, bidPrice);
    uint256 lastBidPriceWithRoyalty = 0;
    uint256 bidPriceWithRoyalty = bidPrice + royaltyInfo.royaltyAmount;

    if (auction.lastBidder != address(0)) {
      address lastBidder = auction.lastBidder;
      uint256 lastBidPrice = auction.highestBid;
      // Transfer back to last bidder
      lastBidPriceWithRoyalty = lastBidPrice + auction.royaltyInfo.royaltyAmount;
      loveToken.safeTransfer(lastBidder, lastBidPriceWithRoyalty);
    }

    reservedBalance += bidPriceWithRoyalty - lastBidPriceWithRoyalty;
    // Set new highest bid price & bidder
    auction.lastBidder = msg.sender;
    auction.highestBid = bidPrice;
    auction.royaltyInfo = royaltyInfo;

    loveToken.safeTransferFrom(msg.sender, address(this), bidPriceWithRoyalty);

    emit PlacedBid(nft.addr, nft.tokenId, bidPrice, msg.sender);
    return bidPriceWithRoyalty;
  }

  /**
   * @notice Result auctions
   * @param nft NFT
   */
  function resultAuction(NFT calldata nft) external returns (uint256) {
    uint256 amount = _resultAuction(nft);
    reservedBalance -= amount;
    return amount;
  }

  /**
   * @notice Result multiple auctions
   * @param nfts NFT (nftAddres, tokenId)
   */
  function resultAuctions(NFT[] calldata nfts) external returns (uint256) {
    uint256 totalAmount = 0;

    for (uint256 i = 0; i < nfts.length; ++i) {
      // Result each auction and accumulate the amount transferred to the auction creator
      uint256 amount = _resultAuction(nfts[i]);
      totalAmount += amount;
    }
    reservedBalance -= totalAmount;
    return totalAmount;
  }

  /**
   * @notice Get auction info by NFT address and token id
   * @param nft NFT address
   * @return AuctionNFT struct
   */
  function getAuction(NFT calldata nft) external view returns (AuctionNFT memory) {
    return auctionNfts[encodeNft(nft)];
  }

  /**
   * @notice Transfer fee to fee receiver contract
   * @dev should set feeReceiver (updateFeeReceiver()) address before call this function
   * @param amount Fee amount
   */
  function transferFee(uint256 amount) external hasRole('admin') {
    require(feeReceiver != address(0), 'invalid feeReceiver address');
    require(getAvailableBalance() >= amount, 'insufficient balance (reserved)');
    loveToken.safeTransfer(feeReceiver, amount);
  }

  /**
   * @notice Set platform fee
   * @param newPlatformFee new platform fee
   */
  function setPlatformFee(uint256 newPlatformFee) external onlyOwner {
    platformFee = newPlatformFee;
    emit ChangedPlatformFee(newPlatformFee);
  }

  /**
   * @notice Set platform fee contract (LoveDrop)
   * @param newFeeReceiver new fee receiver address
   */
  function updateFeeReceiver(address newFeeReceiver) external onlyOwner {
    require(newFeeReceiver != address(0), 'invalid address');
    feeReceiver = newFeeReceiver;

    emit ChangedFeeReceiver(newFeeReceiver);
  }

  /**
   * @notice Calculate fee and amount
   * @param price price
   * @return amount amount transfer to seller
   * @return fee fee transfer to marketplace contract
   */
  function calculateFeeAndAmount(uint256 price) public view returns (uint256 amount, uint256 fee) {
    uint256 fee1e27 = (price * platformFee * 1e27) / 100;
    fee = fee1e27 / 1e27;
    if (fee < MINIMUM_BUYING_FEE) {
      fee = MINIMUM_BUYING_FEE;
    }
    return (price - fee, fee);
  }

  /**
   * @notice Get available balance
   * @return availableBalance available balance (not reserved)
   */
  function getAvailableBalance() public view returns (uint256 availableBalance) {
    return loveToken.balanceOf(address(this)) - reservedBalance;
  }

  function _resultAuction(NFT calldata nft) internal onAuction(nft) returns (uint256) {
    AuctionNFT storage auction = auctionNfts[encodeNft(nft)];
    require(!auction.success, 'already resulted');
    require(block.timestamp > auction.endTime, 'auction not ended');
    address creator = auction.creator;
    address winner = auction.lastBidder;
    uint256 highestBid = auction.highestBid;
    TokenType tokenType = auction.tokenType;
    if (winner == address(0)) {
      // If no one bid, transfer NFT back to creator
      delete auctionNfts[encodeNft(nft)];
      _transferNFT(address(this), creator, nft, tokenType);
      emit CanceledAuction(nft.addr, nft.tokenId);
      return 0;
    }

    auction.success = true;
    auction.winner = winner;
    TokenRoyaltyInfo memory royaltyInfo = auction.royaltyInfo;
    // Calculate royalty fee and transfer to recipient
    _transferRoyalty(royaltyInfo, address(this));

    // Calculate platform fee
    (uint256 amount, ) = calculateFeeAndAmount(highestBid);

    // Transfer to auction creator
    loveToken.safeTransfer(creator, amount);
    // Transfer NFT to the winner
    _transferNFT(address(this), winner, nft, auction.tokenType);

    emit ResultedAuction(nft.addr, nft.tokenId, creator, winner, highestBid, msg.sender);
    return highestBid + royaltyInfo.royaltyAmount;
  }

  function rescueTokens(NFT calldata nft, address receiver) external onlyOwner {
    bool isAuction = auctionNfts[encodeNft(nft)].creator != address(0);
    bool isListed = listNfts[encodeNft(nft)].seller != address(0);
    require(!isListed, 'nft is on sale');
    require(!isAuction, 'nft is on auction');
    TokenType tokenType = _getTokenType(nft.addr);
    _transferNFT(address(this), receiver, nft, tokenType);
  }

  function _tryGetRoyaltyInfo(
    NFT memory nft,
    uint256 price
  ) internal view returns (TokenRoyaltyInfo memory royaltyInfo) {
    if (IERC2981(nft.addr).supportsInterface(type(IERC2981).interfaceId)) {
      (address royaltyRecipient, uint256 amount) = IERC2981(nft.addr).royaltyInfo(nft.tokenId, price);
      if (amount > price / 5) amount = price / 5;
      royaltyInfo = TokenRoyaltyInfo(royaltyRecipient, amount);
    }
    return royaltyInfo;
  }

  function _transferRoyalty(TokenRoyaltyInfo memory royaltyInfo, address from) internal {
    if (royaltyInfo.royaltyReceiver != address(0) && royaltyInfo.royaltyAmount > 0) {
      if (from == address(this)) {
        loveToken.safeTransfer(royaltyInfo.royaltyReceiver, royaltyInfo.royaltyAmount);
      } else {
        loveToken.safeTransferFrom(from, royaltyInfo.royaltyReceiver, royaltyInfo.royaltyAmount);
      }
    }
  }

  function _getTokenType(address nftAddress) internal view returns (TokenType tokenType) {
    if (IERC165(nftAddress).supportsInterface(type(IERC1155).interfaceId)) {
      return TokenType.ERC1155;
    } else if (IERC165(nftAddress).supportsInterface(type(IERC721).interfaceId)) {
      return TokenType.ERC721;
    } else {
      revert('Invalid NFT type');
    }
  }

  function _verifyOwnershipAndApproval(address claimant, NFT memory nft, TokenType tokenType) internal view {
    bool isValid = false;
    if (tokenType == TokenType.ERC1155) {
      isValid =
        IERC1155(nft.addr).balanceOf(claimant, nft.tokenId) >= 1 &&
        IERC1155(nft.addr).isApprovedForAll(claimant, address(this));
    } else if (tokenType == TokenType.ERC721) {
      isValid =
        IERC721(nft.addr).ownerOf(nft.tokenId) == claimant &&
        (IERC721(nft.addr).getApproved(nft.tokenId) == address(this) ||
          IERC721(nft.addr).isApprovedForAll(claimant, address(this)));
    }
    require(isValid, 'not owner or approved tokens');
  }

  function _transferNFT(address from, address to, NFT calldata nft, TokenType tokenType) internal {
    if (tokenType == TokenType.ERC1155) {
      IERC1155(nft.addr).safeTransferFrom(from, to, nft.tokenId, 1, '');
    } else if (tokenType == TokenType.ERC721) {
      IERC721(nft.addr).transferFrom(from, to, nft.tokenId);
    }
  }

  function encodeNft(NFT calldata nft) internal pure returns (bytes32 encodedNft) {
    return keccak256(abi.encodePacked(nft.addr, nft.tokenId));
  }

  function onERC1155Received(
    address,
    address,
    uint256,
    uint256,
    bytes memory
  ) public virtual override returns (bytes4) {
    return this.onERC1155Received.selector;
  }
}
