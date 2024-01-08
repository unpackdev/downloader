// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./IERC1155.sol";
import "./SafeMath.sol";
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./INafterMarketAuction.sol";
import "./INafterRoyaltyRegistry.sol";
import "./IMarketplaceSettings.sol";
import "./Payments.sol";
import "./INafter.sol";

contract NafterMarketAuction is
  Initializable,
  OwnableUpgradeable,
  AccessControlUpgradeable,
  Payments,
  INafterMarketAuction
{
  using SafeMath for uint256;
  /////////////////////////////////////////////////////////////////////////
  // Structs
  /////////////////////////////////////////////////////////////////////////

  // The active bid for a given token, contains the bidder, the marketplace fee at the time of the bid, and the amount of wei placed on the token
  struct ActiveBid {
    address payable bidder;
    uint8 marketplaceFee;
    uint256 amount;
    uint8 paymentMode;
  }

  struct ActiveBidRange {
    uint256 startTime;
    uint256 endTime;
  }

  // The sale price for a given token containing the seller and the amount of wei to be sold for
  struct SalePrice {
    address payable seller;
    uint256 amount;
    uint8 paymentMode;
  }

  /////////////////////////////////////////////////////////////////////////
  // State Variables
  /////////////////////////////////////////////////////////////////////////

  // Marketplace Settings Interface
  IMarketplaceSettings public iMarketplaceSettings;

  // Creator Royalty Interface
  INafterRoyaltyRegistry public iERC1155CreatorRoyalty;

  // Nafter contract
  INafter public nafter;
  //erc1155 contract
  IERC1155 public erc1155;

  // Mapping from ERC1155 contract to mapping of tokenId to sale price.
  mapping(uint256 => mapping(address => SalePrice)) private salePrice;
  // Mapping of ERC1155 contract to mapping of token ID to the current bid amount.
  mapping(uint256 => mapping(address => ActiveBid)) private activeBid;
  mapping(uint256 => mapping(address => ActiveBidRange)) private activeBidRange;

  mapping(address => uint256) public bidBalance;
  // A minimum increase in bid amount when out bidding someone.
  uint8 public minimumBidIncreasePercentage; // 10 = 10%
  uint8 public feeConfig;
  mapping(address => uint256) public nafterBidBalance;
  address public wallet;
  /////////////////////////////////////////////////////////////////////////////
  // Events
  /////////////////////////////////////////////////////////////////////////////
  event Sold(address indexed _buyer, address indexed _seller, uint256 _amount, uint256 _tokenId);

  event Bid(address indexed _bidder, uint256 _amount, uint256 _tokenId);

  event AcceptBid(
    address indexed _bidder,
    address indexed _seller,
    uint256 _amount,
    uint256 _tokenId,
    uint8 _paymentMode
  );

  event CancelBid(address indexed _bidder, uint256 _amount, uint256 _tokenId);

  /////////////////////////////////////////////////////////////////////////
  // Constructor
  /////////////////////////////////////////////////////////////////////////
  /**
   * @dev Initializes the contract setting the market settings and creator royalty interfaces.
   * @param _iMarketSettings address to set as iMarketplaceSettings.
   * @param _iERC1155CreatorRoyalty address to set as iERC1155CreatorRoyalty.
   * @param _nafter address of the nafter contract
   */
  function __NafterMarketAuction_init(
    address _iMarketSettings,
    address _iERC1155CreatorRoyalty,
    address _nafter,
    address _nafterToken
  ) public initializer {
    __Ownable_init();
    __PullPayment_init();
    __AccessControl_init();
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

    // Set iMarketSettings
    iMarketplaceSettings = IMarketplaceSettings(_iMarketSettings);

    // Set iERC1155CreatorRoyalty
    iERC1155CreatorRoyalty = INafterRoyaltyRegistry(_iERC1155CreatorRoyalty);

    nafter = INafter(_nafter);
    erc1155 = IERC1155(_nafter);
    nafterToken = IERC20(_nafterToken);
    minimumBidIncreasePercentage = 10;
    feeConfig = 3;
  }

  receive() external payable {}

  /**
   * @dev set wallet address where funds will send
   * @param _wallet address where funds will send
   */
  function setWallet(address _wallet) external onlyOwner {
    wallet = _wallet;
  }

  /////////////////////////////////////////////////////////////////////////
  // Get token sale price against token id
  /////////////////////////////////////////////////////////////////////////
  /**
   * @dev get the token sale price against token id
   * @param _tokenId uint256 ID of the token
   * @param _owner address of the token owner
   */
  function getSalePrice(uint256 _tokenId, address _owner) external view returns (address payable, uint256) {
    return (salePrice[_tokenId][_owner].seller, salePrice[_tokenId][_owner].amount);
  }

  /**
   * @dev get the token sale price against token id
   * @param _tokenId uint256 ID of the token
   * @param _owner address of the token owner
   */
  function currentSalePrice(uint256 _tokenId, address _owner)
    external
    view
    returns (
      address payable,
      uint256,
      uint8
    )
  {
    return (
      salePrice[_tokenId][_owner].seller,
      salePrice[_tokenId][_owner].amount,
      salePrice[_tokenId][_owner].paymentMode
    );
  }

  /////////////////////////////////////////////////////////////////////////
  // get active bid against tokenId
  /////////////////////////////////////////////////////////////////////////
  /**
   * @dev get active bid against token Id
   * @param _tokenId uint256 ID of the token
   * @param _owner address of the token owner
   */
  function getActiveBid(uint256 _tokenId, address _owner)
    external
    view
    returns (
      address payable,
      uint8,
      uint256
    )
  {
    return (
      activeBid[_tokenId][_owner].bidder,
      activeBid[_tokenId][_owner].marketplaceFee,
      activeBid[_tokenId][_owner].amount
    );
  }

  /////////////////////////////////////////////////////////////////////////
  // has active bid
  /////////////////////////////////////////////////////////////////////////
  /**
   * @dev has active bid
   * @param _tokenId uint256 ID of the token
   * @param _owner address of the token owner
   */
  function hasTokenActiveBid(uint256 _tokenId, address _owner) external view override returns (bool) {
    if (activeBid[_tokenId][_owner].bidder == _owner || activeBid[_tokenId][_owner].bidder == address(0)) return false;

    return true;
  }

  /////////////////////////////////////////////////////////////////////////
  // get active bid range against token id
  /////////////////////////////////////////////////////////////////////////
  /**
   * @dev get active bid range against token id
   * @param _tokenId uint256 ID of the token
   */
  function getActiveBidRange(uint256 _tokenId, address _owner) external view returns (uint256, uint256) {
    return (activeBidRange[_tokenId][_owner].startTime, activeBidRange[_tokenId][_owner].endTime);
  }

  /////////////////////////////////////////////////////////////////////////
  // withdrawMarketFunds
  /////////////////////////////////////////////////////////////////////////
  /**
   * @dev Admin function to withdraw market funds
   * Rules:
   * - only owner
   */
  function withdrawMarketFunds() external onlyOwner {
    payable(owner()).transfer(address(this).balance);
  }

  /////////////////////////////////////////////////////////////////////////
  // seNafter
  /////////////////////////////////////////////////////////////////////////
  /**
   * @dev Admin function to set the marketplace settings.
   * Rules:
   * - only owner
   * - _address != address(0)
   * @param _nafter address of the IMarketplaceSettings.
   */
  function setData(
    address _nafter,
    address _royalty,
    address _token,
    address _marketplaceSettings,
    uint8 _percentage,
    uint8 _feeConfig
  ) public onlyOwner {
    nafter = INafter(_nafter);
    erc1155 = IERC1155(_nafter);
    iERC1155CreatorRoyalty = INafterRoyaltyRegistry(_royalty);
    nafterToken = IERC20(_token);
    iMarketplaceSettings = IMarketplaceSettings(_marketplaceSettings);
    minimumBidIncreasePercentage = _percentage;
    feeConfig = _feeConfig;
  }

  /**
   * @dev Checks that the token is owned by the sender
   * @param _tokenId uint256 ID of the token
   */
  function senderMustBeTokenOwner(uint256 _tokenId) internal view {
    require(
      erc1155.balanceOf(msg.sender, _tokenId) > 0 ||
        msg.sender == address(nafter) ||
        hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
      "owner"
    );
  }

  /////////////////////////////////////////////////////////////////////////
  // setSalePrice
  /////////////////////////////////////////////////////////////////////////
  /**
   * @dev Set the token for sale. The owner of the token must be the sender and have the marketplace approved.
   * @param _tokenId uint256 ID of the token
   * @param _amount uint256 wei value that the item is for sale
   * @param _owner address of the token owner
   * @param _paymentMode 0 for ETH/BNB, 1 for NAFT
   */
  function setSalePrice(
    uint256 _tokenId,
    uint256 _amount,
    address _owner,
    uint8 _paymentMode
  ) external override {
    // The sender must be the token owner
    senderMustBeTokenOwner(_tokenId);

    salePrice[_tokenId][_owner] = SalePrice(payable(_owner), _amount, _paymentMode);
    nafter.setPrice(_amount, _tokenId, _owner);
  }

  /**
   * @dev restore data from old contract, only call by owner
   * @param _oldAddress address of old contract.
   * @param _oldNafterAddress get the token ids from the old nafter contract.
   * @param _startIndex start index of array
   * @param _endIndex end index of array
   */
  function restore(
    address _oldAddress,
    address _oldNafterAddress,
    uint256 _startIndex,
    uint256 _endIndex
  ) external onlyOwner {
    NafterMarketAuction oldContract = NafterMarketAuction(payable(_oldAddress));
    INafter oldNafterContract = INafter(_oldNafterAddress);

    for (uint256 i = _startIndex; i < _endIndex; i++) {
      uint256 tokenId = oldNafterContract.getTokenId(i);

      address[] memory owners = oldNafterContract.getOwners(tokenId);
      for (uint256 j = 0; j < owners.length; j++) {
        address owner = owners[j];
        (address payable sender, uint256 amount) = oldContract.getSalePrice(tokenId, owner);
        salePrice[tokenId][owner] = SalePrice(sender, amount, 0);

        (address payable bidder, uint8 marketplaceFee, uint256 bidAmount) = oldContract.getActiveBid(tokenId, owner);
        activeBid[tokenId][owner] = ActiveBid(bidder, marketplaceFee, bidAmount, 0);
        uint256 serviceFee = bidAmount.mul(marketplaceFee).div(100);
        bidBalance[bidder] = bidBalance[bidder].add(bidAmount.add(serviceFee));

        (uint256 startTime, uint256 endTime) = oldContract.getActiveBidRange(tokenId, owner);
        activeBidRange[tokenId][owner] = ActiveBidRange(startTime, endTime);
      }
    }

    minimumBidIncreasePercentage = oldContract.minimumBidIncreasePercentage();
  }

  /////////////////////////////////////////////////////////////////////////
  // buy
  /////////////////////////////////////////////////////////////////////////
  /**
   * @dev Purchases the token if it is for sale.
   * @param _tokenId uint256 ID of the token.
   * @param _owner address of the token owner
   * @param _paymentMode 0 for ETH/BNB, 1 for NAFT
   */
  function buy(
    uint256 _tokenId,
    address _owner,
    uint8 _paymentMode
  ) public payable {
    uint256 amount = tokenPriceFeeIncluded(_tokenId, _owner);
    uint8 priceType = nafter.getPriceType(_tokenId, _owner);
    require(priceType == 0, "only fixed sale");
    require(nafter.getIsForSale(_tokenId, _owner) == true, "not sale");
    SalePrice memory sp = salePrice[_tokenId][_owner];
    require(sp.paymentMode == _paymentMode, "wrong payment mode");
    // Check that enough ether was sent.
    if (_paymentMode == 0) {
      require(msg.value >= amount, "no correct price");
    }

    _transferNFT(_owner, msg.sender, _tokenId);

    // if the buyer had an existing bid, return it
    if (_addressHasBidOnToken(msg.sender, _tokenId, _owner)) {
      _refundBid(_tokenId, _owner);
    }

    if (_paymentMode == 1) {
      Payments.safeTransferFrom(msg.sender, address(this), sp.amount);
    }
    Payments.payout(
      sp.amount,
      !iMarketplaceSettings.hasTokenSold(_tokenId),
      nafter.getServiceFee(_tokenId),
      iERC1155CreatorRoyalty.getTokenRoyaltyPercentage(_tokenId),
      iMarketplaceSettings.getERC1155ContractPrimarySaleFeePercentage(),
      payable(_owner),
      payable(wallet),
      iERC1155CreatorRoyalty.tokenCreator(_tokenId),
      _paymentMode,
      feeConfig
    );

    // Set token as sold
    iMarketplaceSettings.markERC1155Token(_tokenId, true);

    //remove from sale after buy
    if (erc1155.balanceOf(_owner, _tokenId) == 0) {
      // Wipe the token price.
      _resetTokenPrice(_tokenId, _owner);
      nafter.removeFromSale(_tokenId, _owner);
    }

    emit Sold(msg.sender, _owner, sp.amount, _tokenId);
  }

  /////////////////////////////////////////////////////////////////////////
  // tokenPrice
  /////////////////////////////////////////////////////////////////////////
  /**
   * @dev Gets the sale price of the token
   * @param _tokenId uint256 ID of the token
   * @param _owner address of the token owner
   * @return uint256 sale price of the token
   */
  function tokenPrice(uint256 _tokenId, address _owner) external view returns (uint256) {
    return salePrice[_tokenId][_owner].amount;
  }

  /////////////////////////////////////////////////////////////////////////
  // tokenPriceFeeIncluded
  /////////////////////////////////////////////////////////////////////////
  /**
   * @dev Gets the sale price of the token including the marketplace fee.
   * @param _tokenId uint256 ID of the token
   * @param _owner address of the token owner
   * @return uint256 sale price of the token including the fee.
   */
  function tokenPriceFeeIncluded(uint256 _tokenId, address _owner) public view returns (uint256) {
    if (feeConfig == 2 || feeConfig == 3)
      return
        salePrice[_tokenId][_owner].amount.add(
          salePrice[_tokenId][_owner].amount.mul(nafter.getServiceFee(_tokenId)).div(100)
        );

    return salePrice[_tokenId][_owner].amount;
  }

  /////////////////////////////////////////////////////////////////////////
  // setInitialBidPriceWithRange
  /////////////////////////////////////////////////////////////////////////
  /**
   * @dev set initial bid with range
   * @param _bidAmount uint256 value in wei to bid.
   * @param _startTime end time of bid
   * @param _endTime end time of bid
   * @param _owner address of the token owner
   * @param _tokenId uint256 ID of the token
   * @param _paymentMode 0 for ETH/BNB, 1 for NAFT
   */
  function setInitialBidPriceWithRange(
    uint256 _bidAmount,
    uint256 _startTime,
    uint256 _endTime,
    address _owner,
    uint256 _tokenId,
    uint8 _paymentMode
  ) external override {
    senderMustBeTokenOwner(_tokenId);

    activeBid[_tokenId][_owner] = ActiveBid(payable(_owner), nafter.getServiceFee(_tokenId), _bidAmount, _paymentMode);
    activeBidRange[_tokenId][_owner] = ActiveBidRange(_startTime, _endTime);
  }

  /////////////////////////////////////////////////////////////////////////
  // bid
  /////////////////////////////////////////////////////////////////////////
  /**
   * @dev Bids on the token, replacing the bid if the bid is higher than the current bid. You cannot bid on a token you already own.
   * @param _newBidAmount uint256 value in wei to bid.
   * @param _tokenId uint256 ID of the token
   * @param _owner address of the token owner
   * @param _paymentMode 0 for ETH/BNB, 1 for NAFT
   */
  function bid(
    uint256 _newBidAmount,
    uint256 _tokenId,
    address _owner,
    uint8 _paymentMode
  ) external payable {
    if (_paymentMode == 0) {
      uint256 amount = feeConfig == 2 || feeConfig == 3
        ? _newBidAmount.add(_newBidAmount.mul(nafter.getServiceFee(_tokenId)).div(100))
        : _newBidAmount;
      require(msg.value >= amount, "no correct price");
    }
    require(nafter.getIsForSale(_tokenId, _owner) == true, "not for sale");
    //Check bid range
    uint8 priceType = nafter.getPriceType(_tokenId, _owner);

    require(priceType == 1 || priceType == 2, "no fixed sale");
    if (priceType == 1)
      require(
        activeBidRange[_tokenId][_owner].startTime < block.timestamp &&
          activeBidRange[_tokenId][_owner].endTime > block.timestamp,
        "cant place bid"
      );

    uint256 currentBidAmount = activeBid[_tokenId][_owner].amount;
    require(
      _newBidAmount >= currentBidAmount.add(currentBidAmount.mul(minimumBidIncreasePercentage).div(100)),
      "high minimum percentage"
    );
    require(activeBid[_tokenId][_owner].paymentMode == _paymentMode, "wrong payment");

    // Refund previous bidder.
    _refundBid(_tokenId, _owner);
    //transfer naft tokens to contracts
    if (_paymentMode == 1) {
      Payments.safeTransferFrom(msg.sender, address(this), _newBidAmount);
    }
    // Set the new bid.
    _setBid(_newBidAmount, payable(msg.sender), _tokenId, _owner, _paymentMode);
    nafter.setBid(_newBidAmount, msg.sender, _tokenId, _owner);
    emit Bid(msg.sender, _newBidAmount, _tokenId);
  }

  /**
   * @dev Auto approve and transfer. Default send 1 per time
   * @param _fr address from
   * @param _to address receiver
   * @param _id uint256 ID of the token
   */
  function _transferNFT(
    address _fr,
    address _to,
    uint _id
  ) private {
    nafter.setApprovalForAllByNMA(_fr, address(this), true);
    erc1155.safeTransferFrom(_fr, _to, _id, 1, "");
  }

  /////////////////////////////////////////////////////////////////////////
  // acceptBid
  /////////////////////////////////////////////////////////////////////////
  /**
   * @dev Accept the bid on the token.
   * @param _tokenId uint256 ID of the token
   * @param _owner address of the token owner
   */
  function acceptBid(uint256 _tokenId, address _owner) public {
    // The sender must be the token owner
    senderMustBeTokenOwner(_tokenId);

    // Check that a bid exists.
    require(activeBid[_tokenId][_owner].bidder != address(0), "no bid");

    // Get current bid on token

    ActiveBid memory currentBid = activeBid[_tokenId][_owner];

    // Transfer token.
    _transferNFT(_owner, currentBid.bidder, _tokenId);

    Payments.payout(
      currentBid.amount,
      !iMarketplaceSettings.hasTokenSold(_tokenId),
      nafter.getServiceFee(_tokenId),
      iERC1155CreatorRoyalty.getTokenRoyaltyPercentage(_tokenId),
      iMarketplaceSettings.getERC1155ContractPrimarySaleFeePercentage(),
      payable(_owner),
      payable(wallet),
      iERC1155CreatorRoyalty.tokenCreator(_tokenId),
      currentBid.paymentMode,
      feeConfig
    );

    iMarketplaceSettings.markERC1155Token(_tokenId, true);
    if (currentBid.paymentMode == 0) {
      uint256 serviceFee = feeConfig == 2 || feeConfig == 3
        ? currentBid.amount.mul(currentBid.marketplaceFee).div(100)
        : 0;
      bidBalance[currentBid.bidder] = bidBalance[currentBid.bidder].sub(currentBid.amount.add(serviceFee));
    } else {
      nafterBidBalance[currentBid.bidder] = nafterBidBalance[currentBid.bidder].sub(currentBid.amount);
    }
    uint8 paymentMode = currentBid.paymentMode;
    if (erc1155.balanceOf(_owner, _tokenId) == 0) {
      _resetTokenPrice(_tokenId, _owner);
      _resetBid(_tokenId, _owner);

      //remove from sale after accepting the bid
      nafter.removeFromSale(_tokenId, _owner);
    } else {
      activeBid[_tokenId][_owner].bidder = payable(address(0));
    }
    // Wipe the token price and bid.
    emit AcceptBid(currentBid.bidder, msg.sender, currentBid.amount, _tokenId, paymentMode);
  }

  /**
   * @dev lazy mintng to bid
   * @param _tokenAmount total token amount available
   * @param _price price of the token, 0 is for not set the price.
   * @param _priceType 0 is for fixed, 1 is for Auction Time bound, 2 is for Auction Infinite
   * @param _royaltyPercentage royalty percentage of creator
   * @param _startTime start time of bid, pass 0 of _priceType is not 1
   * @param _endTime end time of bid, pass 0 of _priceType is not 1
   * @param _tokenId uint256 token id
   * @param _signature data signature to return account information
   * @param _paymentMode 0 for ETH/BNB, 1 for NAFT
   * @param _signature data signature to return account information
   * @param _creator address of the creator of the token.
   * @param _newBidAmount new Bid Amount including
   */
  function lazyMintingBid(
    uint256 _tokenAmount,
    uint256 _price,
    uint8 _priceType,
    uint8 _royaltyPercentage,
    uint256 _startTime,
    uint256 _endTime,
    uint256 _tokenId,
    uint8 _paymentMode,
    bytes calldata _signature,
    address _creator,
    uint256 _newBidAmount
  ) external payable {
    require(_priceType == 1 || _priceType == 2, "no fixed sale");
    if (_priceType == 1) require(_startTime < block.timestamp && _endTime > block.timestamp, "cant place bid");
    require(_newBidAmount >= _price.add(_price.mul(minimumBidIncreasePercentage).div(100)), "high minimum percentage");
    nafter.verify(
      _creator,
      _tokenAmount,
      true,
      _price,
      _priceType, //price type is 0
      _royaltyPercentage,
      _startTime,
      _endTime,
      _tokenId,
      _paymentMode,
      _signature
    );

    nafter.addNewTokenAndSetThePriceWithIdAndMinter(
      _tokenAmount,
      true,
      _price,
      _priceType,
      _royaltyPercentage,
      _tokenId,
      _creator,
      _creator
    );

    // uint8 serviceFee = nafter.getServiceFee(_tokenId);
    if (_paymentMode == 0) {
      uint256 amount = feeConfig == 2 || feeConfig == 3
        ? _newBidAmount.add(_newBidAmount.mul(nafter.getServiceFee(_tokenId)).div(100))
        : _newBidAmount;
      require(msg.value >= amount, "wrong amount");
    }

    _setBid(_newBidAmount, payable(msg.sender), _tokenId, _creator, _paymentMode);
    activeBidRange[_tokenId][_creator] = ActiveBidRange(_startTime, _endTime);

    nafter.setBid(_price, msg.sender, _tokenId, _creator);

    if (_paymentMode == 1) {
      Payments.safeTransferFrom(msg.sender, address(this), _newBidAmount);
    }
  }

  /**
   * @dev lazy mintng to buy
   * @param _creator address of the creator of the token.
   * @param _tokenAmount total token amount available
   * @param _isForSale if is for sale
   * @param _price price of the token, 0 is for not set the price.
   * @param _royaltyPercentage royalty percentage of creator
   * @param _tokenId uint256 token id
   * @param _paymentMode 0 for ETH/BNB, 1 for NAFT
   */
  function lazyMintingBuy(
    uint256 _tokenAmount,
    bool _isForSale,
    uint256 _price,
    uint8 _royaltyPercentage,
    uint256 _tokenId,
    uint8 _paymentMode,
    bytes calldata _signature,
    address _creator
  ) external payable {
    nafter.verify(
      _creator,
      _tokenAmount,
      _isForSale,
      _price,
      0, //price type is 0
      _royaltyPercentage,
      0,
      0,
      _tokenId,
      _paymentMode,
      _signature
    );
    // in case of by, mint token on buyer
    //direct token transfer
    nafter.addNewTokenAndSetThePriceWithIdAndMinter(
      _tokenAmount,
      _isForSale,
      _price,
      0,
      _royaltyPercentage,
      _tokenId,
      _creator,
      _creator
    );
    salePrice[_tokenId][_creator] = SalePrice(payable(_creator), _price, _paymentMode);
    nafter.setPrice(_price, _tokenId, _creator);

    if (_paymentMode == 0) {
      uint256 amount = feeConfig == 2 || feeConfig == 3 ? tokenPriceFeeIncluded(_tokenId, _creator) : _price;
      require(msg.value >= amount, "no correct price");
    }

    _transferNFT(_creator, msg.sender, _tokenId);

    if (_paymentMode == 1) {
      Payments.safeTransferFrom(msg.sender, address(this), _price);
    }
    Payments.payout(
      _price,
      !iMarketplaceSettings.hasTokenSold(_tokenId),
      nafter.getServiceFee(_tokenId),
      iERC1155CreatorRoyalty.getTokenRoyaltyPercentage(_tokenId),
      iMarketplaceSettings.getERC1155ContractPrimarySaleFeePercentage(),
      payable(_creator),
      payable(wallet),
      iERC1155CreatorRoyalty.tokenCreator(_tokenId),
      _paymentMode,
      feeConfig
    );
    //remove from sale after buy
    if (erc1155.balanceOf(_creator, _tokenId) == 0) {
      // Wipe the token price.
      _resetTokenPrice(_tokenId, _creator);
      nafter.removeFromSale(_tokenId, _creator);
    }
  }

  /////////////////////////////////////////////////////////////////////////
  // cancelBid
  /////////////////////////////////////////////////////////////////////////
  /**
   * @dev Cancel the bid on the token.
   * @param _tokenId uint256 ID of the token.
   * @param _owner address of the token owner
   */
  function cancelBid(uint256 _tokenId, address _owner) external {
    // Check that sender has a current bid.
    require(_addressHasBidOnToken(msg.sender, _tokenId, _owner), "cant cancel");

    _refundBid(_tokenId, _owner);

    emit CancelBid(msg.sender, activeBid[_tokenId][_owner].amount, _tokenId);
  }

  /////////////////////////////////////////////////////////////////////////
  // currentBidDetailsOfToken
  /////////////////////////////////////////////////////////////////////////
  /**
   * @dev Function to get current bid and bidder of a token.
   * @param _tokenId uin256 id of the token.
   * @param _owner address of the token owner
   */
  function currentBidDetailsOfToken(uint256 _tokenId, address _owner)
    public
    view
    returns (
      uint256,
      address,
      uint8
    )
  {
    return (
      activeBid[_tokenId][_owner].amount,
      activeBid[_tokenId][_owner].bidder,
      activeBid[_tokenId][_owner].paymentMode
    );
  }

  /////////////////////////////////////////////////////////////////////////
  // _resetTokenPrice
  /////////////////////////////////////////////////////////////////////////
  /**
   * @dev Internal function to set token price to 0 for a given contract.
   * @param _tokenId uin256 id of the token.
   * @param _owner address of the token owner
   */
  function _resetTokenPrice(uint256 _tokenId, address _owner) internal {
    salePrice[_tokenId][_owner] = SalePrice(payable(address(0)), 0, 0);
  }

  /////////////////////////////////////////////////////////////////////////
  // _addressHasBidOnToken
  /////////////////////////////////////////////////////////////////////////
  /**
   * @dev Internal function see if the given address has an existing bid on a token.
   * @param _bidder address that may have a current bid.
   * @param _tokenId uin256 id of the token.
   * @param _owner address of the token owner
   */
  function _addressHasBidOnToken(
    address _bidder,
    uint256 _tokenId,
    address _owner
  ) internal view returns (bool) {
    return activeBid[_tokenId][_owner].bidder == _bidder;
  }

  /////////////////////////////////////////////////////////////////////////
  // _refundBid
  /////////////////////////////////////////////////////////////////////////
  /**
   * @dev Internal function to return an existing bid on a token to the
   *      bidder and reset bid.
   * @param _tokenId uin256 id of the token.
   * @param _owner address of the token owner
   */
  function _refundBid(uint256 _tokenId, address _owner) internal {
    ActiveBid memory currentBid = activeBid[_tokenId][_owner];
    if (currentBid.bidder == address(0) || currentBid.bidder == _owner) {
      return;
    }
    //current bidder should not be owner
    if (currentBid.paymentMode == 0) {
      if (bidBalance[currentBid.bidder] > 0) {
        Payments.refund(currentBid.marketplaceFee, currentBid.bidder, currentBid.amount);
        //subtract bid balance
        uint256 serviceFee = feeConfig == 2 || feeConfig == 3
          ? currentBid.amount.mul(currentBid.marketplaceFee).div(100)
          : currentBid.amount;

        bidBalance[currentBid.bidder] = bidBalance[currentBid.bidder].sub(currentBid.amount.add(serviceFee));
      }
    } else {
      if (nafterBidBalance[currentBid.bidder] > 0) {
        Payments.safeTransfer(currentBid.bidder, currentBid.amount);
        nafterBidBalance[currentBid.bidder] = nafterBidBalance[currentBid.bidder].sub(currentBid.amount);
      }
    }
    _resetBid(_tokenId, _owner);
  }

  /////////////////////////////////////////////////////////////////////////
  // _resetBid
  /////////////////////////////////////////////////////////////////////////
  /**
   * @dev Internal function to reset bid by setting bidder and bid to 0.
   * @param _tokenId uin256 id of the token.
   * @param _owner address of the token owner
   */
  function _resetBid(uint256 _tokenId, address _owner) internal {
    activeBid[_tokenId][_owner] = ActiveBid(payable(address(0)), 0, 0, 0);
  }

  /////////////////////////////////////////////////////////////////////////
  // _setBid
  /////////////////////////////////////////////////////////////////////////
  /**
   * @dev Internal function to set a bid.
   * @param _amount uint256 value in wei to bid. Does not include marketplace fee.
   * @param _bidder address of the bidder.
   * @param _tokenId uin256 id of the token.
   * @param _owner address of the token owner
   * @param _paymentMode 0 for ETH/BNB, 1 for NAFT
   */
  function _setBid(
    uint256 _amount,
    address payable _bidder,
    uint256 _tokenId,
    address _owner,
    uint8 _paymentMode
  ) internal {
    // Check bidder not 0 address.
    require(_bidder != address(0), "no 0 address");

    // Set bid.
    activeBid[_tokenId][_owner] = ActiveBid(_bidder, nafter.getServiceFee(_tokenId), _amount, _paymentMode);
    //add bid balance
    if (_paymentMode == 0) {
      bidBalance[_bidder] = feeConfig == 2 || feeConfig == 3
        ? bidBalance[_bidder].add(_amount.add(_amount.mul(nafter.getServiceFee(_tokenId)).div(100)))
        : bidBalance[_bidder].add(_amount);
    } else {
      nafterBidBalance[_bidder] = nafterBidBalance[_bidder].add(_amount);
    }
  }
}
