// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./IERC1155.sol";
import "./IERC721.sol";
import "./SafeMath.sol";
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./IERC1155ReceiverUpgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./ERC165CheckerUpgradeable.sol";

import "./INafterRoyaltyRegistry.sol";
import "./IMarketplaceSettings.sol";
import "./Payments.sol";

contract NafterMarketAuctionExternal is
  Initializable,
  OwnableUpgradeable,
  AccessControlUpgradeable,
  Payments,
  IERC1155ReceiverUpgradeable,
  IERC721ReceiverUpgradeable
{
  using SafeMath for uint256;
  using ERC165CheckerUpgradeable for address;

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

  struct TokenInfo {
    uint256 tokenId;
    address creator;
    address[] owners;
    uint8 serviceFee;
    uint256 creationTime;
    uint8 nftType;
  }

  struct TokenOwnerInfo {
    bool isForSale;
    uint8 priceType; // 0 for fixed, 1 for Auction dates range, 2 for Auction Infinity
    uint256[] prices;
    uint256[] bids;
    address[] bidders;
    uint256 tokenAmount;
  }
  /////////////////////////////////////////////////////////////////////////
  // State Variables
  /////////////////////////////////////////////////////////////////////////

  // Marketplace Settings Interface
  IMarketplaceSettings public iMarketplaceSettings;

  // Creator Royalty Interface
  INafterRoyaltyRegistry public iERC1155CreatorRoyalty;

  // Mapping from ERC1155 contract to mapping of tokenId to sale price.
  mapping(address => mapping(uint256 => mapping(address => SalePrice))) private salePrice;
  // Mapping of ERC1155 contract to mapping of token ID to the current bid amount.
  mapping(address => mapping(uint256 => mapping(address => ActiveBid))) private activeBid;
  mapping(address => mapping(uint256 => mapping(address => ActiveBidRange))) private activeBidRange;

  mapping(address => uint256) public bidBalance;
  // A minimum increase in bid amount when out bidding someone.
  uint8 public minimumBidIncreasePercentage; // 10 = 10%
  uint8 public feeConfig;
  mapping(address => uint256) public nafterBidBalance;
  address public wallet;
  mapping(uint256 => mapping(address => uint256)) public tokenInContract;

  mapping(address => mapping(uint256 => TokenInfo)) public tokenInfo;
  mapping(address => mapping(uint256 => mapping(address => TokenOwnerInfo))) public tokenOwnerInfo;

  bytes4 public constant IID_IERC1155 = type(IERC1155).interfaceId;
  bytes4 public constant IID_IERC721 = type(IERC721).interfaceId;

  /////////////////////////////////////////////////////////////////////////////
  // Events
  /////////////////////////////////////////////////////////////////////////////
  event Sold(address indexed _buyer, address indexed _seller, uint256 _amount, uint256 _tokenId);

  event Bid(address indexed _bidder, uint256 _amount, uint256 _tokenId);

  event AddNewToken(address user, uint256 tokenId);

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
   */
  function __NafterMarketAuctionExternal_init(
    address _iMarketSettings,
    address _iERC1155CreatorRoyalty,
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

    nafterToken = IERC20(_nafterToken);
    minimumBidIncreasePercentage = 10;
    feeConfig = 3;
  }

  // receive() external payable {}

  function onERC1155Received(
    address _operator,
    address _owner,
    uint256 _tokenId,
    uint256 _amount,
    bytes memory
  ) public virtual override returns (bytes4) {
    require(_operator == address(this), "self");
    _addTokenToNafterMarket(_owner, _tokenId, _amount);
    return this.onERC1155Received.selector;
  }

  function onERC721Received(
    address _operator,
    address _owner,
    uint256 _tokenId,
    bytes calldata
  ) external override returns (bytes4) {
    require(_operator == address(this), "self");
    _addTokenToNafterMarket(_owner, _tokenId, 1);
    return this.onERC721Received.selector;
  }

  function onERC1155BatchReceived(
    address,
    address,
    uint256[] calldata,
    uint256[] calldata,
    bytes calldata
  ) external virtual override returns (bytes4) {
    return this.onERC1155BatchReceived.selector;
  }

  /**
   * @dev set wallet address where funds will send
   * @param _wallet address where funds will send
   */
  function setWallet(address _wallet) external onlyOwner {
    wallet = _wallet;
  }

  /**
   * @dev get the token sale price against token id
   * @param _tokenId uint256 ID of the token
   * @param _owner address of the token owner
   * @param _contractAddress address of NFT Contract, contract should be ERC1155 or NFT standard
   */
  function currentSalePrice(
    uint256 _tokenId,
    address _owner,
    address _contractAddress
  )
    external
    view
    returns (
      address payable,
      uint256,
      uint8
    )
  {
    return (
      salePrice[_contractAddress][_tokenId][_owner].seller,
      salePrice[_contractAddress][_tokenId][_owner].amount,
      salePrice[_contractAddress][_tokenId][_owner].paymentMode
    );
  }

  /**
   * @dev get the token amount
   * @param _tokenId uint256 ID of the token
   * @param _owner address of the token owner
   * @param _contractAddress address of NFT Contract, contract should be ERC1155 or NFT standard
   */
  function getTokenAmount(
    uint256 _tokenId,
    address _owner,
    address _contractAddress
  ) external view returns (uint256) {
    return tokenOwnerInfo[_contractAddress][_tokenId][_owner].tokenAmount;
  }

  /////////////////////////////////////////////////////////////////////////
  // get active bid against tokenId
  /////////////////////////////////////////////////////////////////////////
  /**
   * @dev get active bid against token Id
   * @param _tokenId uint256 ID of the token
   * @param _owner address of the token owner
   * @param _contractAddress address of NFT Contract, contract should be ERC1155 or NFT standard
   */
  function getActiveBid(
    uint256 _tokenId,
    address _owner,
    address _contractAddress
  )
    external
    view
    returns (
      address payable,
      uint8,
      uint256
    )
  {
    return (
      activeBid[_contractAddress][_tokenId][_owner].bidder,
      activeBid[_contractAddress][_tokenId][_owner].marketplaceFee,
      activeBid[_contractAddress][_tokenId][_owner].amount
    );
  }

  /////////////////////////////////////////////////////////////////////////
  // get active bid range against token id
  /////////////////////////////////////////////////////////////////////////
  /**
   * @dev get active bid range against token id
   * @param _tokenId uint256 ID of the token
   * @param _contractAddress address of NFT Contract, contract should be ERC1155 or NFT standard
   */
  function getActiveBidRange(
    uint256 _tokenId,
    address _owner,
    address _contractAddress
  ) external view returns (uint256, uint256) {
    return (
      activeBidRange[_contractAddress][_tokenId][_owner].startTime,
      activeBidRange[_contractAddress][_tokenId][_owner].endTime
    );
  }

  // /////////////////////////////////////////////////////////////////////////
  // // withdrawMarketFunds
  // /////////////////////////////////////////////////////////////////////////
  // /**
  //  * @dev Admin function to withdraw market funds
  //  * Rules:
  //  * - only owner
  //  */
  // function withdrawMarketFunds() external onlyOwner {
  //   payable(owner()).transfer(address(this).balance);
  // }

  /////////////////////////////////////////////////////////////////////////
  // setData
  /////////////////////////////////////////////////////////////////////////
  /**
   * @dev Admin function to set the marketplace settings.
   * Rules:
   * - only owner
   * - _address != address(0)
   */
  function setData(
    address _royalty,
    address _token,
    address _marketplaceSettings,
    uint8 _percentage,
    uint8 _feeConfig
  ) public onlyOwner {
    iERC1155CreatorRoyalty = INafterRoyaltyRegistry(_royalty);
    nafterToken = IERC20(_token);
    iMarketplaceSettings = IMarketplaceSettings(_marketplaceSettings);
    minimumBidIncreasePercentage = _percentage;
    feeConfig = _feeConfig;
  }

  /**
   * @dev Checks that the token is owned by the sender
   * @param _tokenId uint256 ID of the token
   * @param _contractAddress address of the NFT contract, the contract should be ERC1155 or ERC721
   */
  function senderMustBeTokenOwner(uint256 _tokenId, address _contractAddress) internal view {
    require(
      // tokenInContract[_tokenId][msg.sender] > 0 ||
      tokenOwnerInfo[_contractAddress][_tokenId][msg.sender].tokenAmount > 0,
      "owner"
    );
  }

  /////////////////////////////////////////////////////////////////////////
  // buy
  /////////////////////////////////////////////////////////////////////////
  /**
   * @dev Purchases the token if it is for sale.
   * @param _tokenId uint256 ID of the token.
   * @param _owner address of the token owner
   * @param _paymentMode 0 for ETH/BNB, 1 for NAFT
   * @param _contractAddress address of the NFT contract, the contract should be ERC1155 or ERC721
   */
  function buy(
    uint256 _tokenId,
    address _owner,
    uint8 _paymentMode,
    address _contractAddress
  ) public payable {
    uint256 amount = tokenPriceFeeIncluded(_tokenId, _owner, _contractAddress);
    require(tokenOwnerInfo[_contractAddress][_tokenId][_owner].priceType == 0, "only fixed sale");
    require(tokenOwnerInfo[_contractAddress][_tokenId][_owner].isForSale == true, "not sale");

    // SalePrice memory sp = salePrice[_tokenId][_owner];
    require(salePrice[_contractAddress][_tokenId][_owner].paymentMode == _paymentMode, "wrong payment mode");
    // Check that enough ether was sent.
    if (_paymentMode == 0) {
      require(msg.value >= amount, "no correct price");
    }
    require(tokenInContract[_tokenId][_owner] > 0, "no balance");

    _transferNFT(
      address(this),
      msg.sender,
      _tokenId,
      1,
      _contractAddress,
      tokenInfo[_contractAddress][_tokenId].nftType
    );
    tokenInContract[_tokenId][_owner] = tokenInContract[_tokenId][_owner] - 1;
    tokenOwnerInfo[_contractAddress][_tokenId][_owner].tokenAmount =
      tokenOwnerInfo[_contractAddress][_tokenId][_owner].tokenAmount -
      1;

    if (_paymentMode == 1) {
      Payments.safeTransferFrom(msg.sender, address(this), salePrice[_contractAddress][_tokenId][_owner].amount);
    }
    Payments.payout(
      salePrice[_contractAddress][_tokenId][_owner].amount,
      !iMarketplaceSettings.hasTokenSold(_tokenId),
      tokenInfo[_contractAddress][_tokenId].serviceFee,
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
    uint256 oldSalePrice = salePrice[_contractAddress][_tokenId][_owner].amount;
    //remove from sale after buy
    if (tokenOwnerInfo[_contractAddress][_tokenId][_owner].tokenAmount == 0) {
      // Wipe the token price.
      _resetTokenPrice(_tokenId, _owner, _contractAddress);
    }

    emit Sold(msg.sender, _owner, oldSalePrice, _tokenId);
  }

  /////////////////////////////////////////////////////////////////////////
  // tokenPrice
  /////////////////////////////////////////////////////////////////////////
  /**
   * @dev Gets the sale price of the token
   * @param _tokenId uint256 ID of the token
   * @param _owner address of the token owner
   * @param _contractAddress address of NFT Contract, contract should be ERC1155 or NFT standard
   * @return uint256 sale price of the token
   */
  function tokenPrice(
    uint256 _tokenId,
    address _owner,
    address _contractAddress
  ) external view returns (uint256) {
    return salePrice[_contractAddress][_tokenId][_owner].amount;
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
  function tokenPriceFeeIncluded(
    uint256 _tokenId,
    address _owner,
    address _contractAddress
  ) public view returns (uint256) {
    if (feeConfig == 2 || feeConfig == 3)
      return
        salePrice[_contractAddress][_tokenId][_owner].amount.add(
          salePrice[_contractAddress][_tokenId][_owner]
            .amount
            .mul(tokenInfo[_contractAddress][_tokenId].serviceFee)
            .div(100)
        );

    return salePrice[_contractAddress][_tokenId][_owner].amount;
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
   * @param _contractAddress address of NFT Contract, contract should be ERC1155 or NFT standard
   */
  function bid(
    uint256 _newBidAmount,
    uint256 _tokenId,
    address _owner,
    uint8 _paymentMode,
    address _contractAddress
  ) external payable {
    if (_paymentMode == 0) {
      uint256 amount = feeConfig == 2 || feeConfig == 3
        ? _newBidAmount.add(_newBidAmount.mul(tokenInfo[_contractAddress][_tokenId].serviceFee).div(100))
        : _newBidAmount;
      require(msg.value >= amount, "no correct price");
    }
    // (bool isForSale, uint8 priceType, , , ) = nafter.getTokenOwnerInfo(_tokenId, _owner);
    require(tokenInContract[_tokenId][_owner] > 0, "no balance");
    require(tokenOwnerInfo[_contractAddress][_tokenId][_owner].isForSale == true, "not for sale");

    uint8 priceType = tokenOwnerInfo[_contractAddress][_tokenId][_owner].priceType;
    require(priceType == 1 || priceType == 2, "no fixed sale");
    if (priceType == 1)
      require(
        activeBidRange[_contractAddress][_tokenId][_owner].startTime < block.timestamp &&
          activeBidRange[_contractAddress][_tokenId][_owner].endTime > block.timestamp,
        "cant place bid"
      );

    uint256 currentBidAmount = activeBid[_contractAddress][_tokenId][_owner].amount;
    require(
      _newBidAmount >= currentBidAmount.add(currentBidAmount.mul(minimumBidIncreasePercentage).div(100)),
      "high minimum percentage"
    );
    require(activeBid[_contractAddress][_tokenId][_owner].paymentMode == _paymentMode, "wrong payment");

    // Refund previous bidder.
    _refundBid(_tokenId, _owner, _contractAddress);
    //transfer naft tokens to contracts
    if (_paymentMode == 1) {
      Payments.safeTransferFrom(msg.sender, address(this), _newBidAmount);
    }
    // Set the new bid.
    _setBid(_newBidAmount, payable(msg.sender), _tokenId, _owner, _paymentMode, _contractAddress);
    _setOwnerBid(_newBidAmount, msg.sender, _tokenId, _owner, _contractAddress);
    emit Bid(msg.sender, _newBidAmount, _tokenId);
  }

  /**
   * @dev Auto approve and transfer. Default send 1 per time
   * @param _fr address from
   * @param _to address receiver
   * @param _id uint256 ID of the token
   * @param _amount amount of token to transfer
   * @param _contractAddress address of NFT Contract, contract should be ERC1155 or NFT standard
   */
  function _transferNFT(
    address _fr,
    address _to,
    uint256 _id,
    uint256 _amount,
    address _contractAddress,
    uint8 _nftType
  ) private {
    if (_nftType == 0) IERC1155(_contractAddress).safeTransferFrom(_fr, _to, _id, _amount, "");
    else IERC721(_contractAddress).safeTransferFrom(_fr, _to, _id);
  }

  /////////////////////////////////////////////////////////////////////////
  // acceptBid
  /////////////////////////////////////////////////////////////////////////
  /**
   * @dev Accept the bid on the token.
   * @param _tokenId uint256 ID of the token
   * @param _owner address of the token owner
   * @param _contractAddress address of the NFT contract, the contract should be ERC1155 or ERC721
   */
  function acceptBid(
    uint256 _tokenId,
    address _owner,
    address _contractAddress
  ) public {
    // The sender must be the token owner
    senderMustBeTokenOwner(_tokenId, _contractAddress);

    // Check that a bid exists.
    require(activeBid[_contractAddress][_tokenId][_owner].bidder != address(0), "no bid");

    // Get current bid on token

    ActiveBid memory currentBid = activeBid[_contractAddress][_tokenId][_owner];

    // Transfer token.
    _transferNFT(
      address(this),
      currentBid.bidder,
      _tokenId,
      1,
      _contractAddress,
      tokenInfo[_contractAddress][_tokenId].nftType
    );
    tokenInContract[_tokenId][_owner] = tokenInContract[_tokenId][_owner] - 1;
    tokenOwnerInfo[_contractAddress][_tokenId][_owner].tokenAmount =
      tokenOwnerInfo[_contractAddress][_tokenId][_owner].tokenAmount -
      1;

    Payments.payout(
      currentBid.amount,
      !iMarketplaceSettings.hasTokenSold(_tokenId),
      tokenInfo[_contractAddress][_tokenId].serviceFee,
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
    uint256 bidAmount = currentBid.amount;
    if (tokenOwnerInfo[_contractAddress][_tokenId][_owner].tokenAmount == 0) {
      _resetTokenPrice(_tokenId, _owner, _contractAddress);
      // _resetBid(_tokenId, _owner);
      //remove from sale after accepting the bid
      // nafter.removeFromSale(_tokenId, _owner);
    } else {
      activeBid[_contractAddress][_tokenId][_owner].bidder = payable(address(0));
    }
    // Wipe the token price and bid.
    emit AcceptBid(currentBid.bidder, msg.sender, bidAmount, _tokenId, paymentMode);
  }

  /////////////////////////////////////////////////////////////////////////
  // cancelBid
  /////////////////////////////////////////////////////////////////////////
  /**
   * @dev Cancel the bid on the token.
   * @param _tokenId uint256 ID of the token.
   * @param _owner address of the token owner
   * @param _contractAddress address of NFT Contract, contract should be ERC1155 or NFT standard
   */
  function cancelBid(
    uint256 _tokenId,
    address _owner,
    address _contractAddress
  ) external {
    require(activeBid[_contractAddress][_tokenId][_owner].bidder == msg.sender, "cant cancel");
    _refundBid(_tokenId, _owner, _contractAddress);

    emit CancelBid(msg.sender, activeBid[_contractAddress][_tokenId][_owner].amount, _tokenId);
  }

  /////////////////////////////////////////////////////////////////////////
  // currentBidDetailsOfToken
  /////////////////////////////////////////////////////////////////////////
  /**
   * @dev Function to get current bid and bidder of a token.
   * @param _tokenId uin256 id of the token.
   * @param _owner address of the token owner
   * @param _contractAddress address of NFT Contract, contract should be ERC1155 or NFT standard
   */
  function currentBidDetailsOfToken(
    uint256 _tokenId,
    address _owner,
    address _contractAddress
  )
    public
    view
    returns (
      uint256,
      address,
      uint8
    )
  {
    return (
      activeBid[_contractAddress][_tokenId][_owner].amount,
      activeBid[_contractAddress][_tokenId][_owner].bidder,
      activeBid[_contractAddress][_tokenId][_owner].paymentMode
    );
  }

  /**
   * @dev external function to import nft to contract.
   * @param _priceType set the price type
   * @param _price price of the token
   * @param _startTime start time of bid, pass 0 of _priceType is not 1
   * @param _endTime end time of bid, pass 0 of _priceType is not 1
   * @param _tokenId uint256 id of the token.
   * @param _paymentMode 0 for ETH/BNB, 1 for NAFT
   * @param _amount amount of the token needs to send to contract
   * @param _contractAddress address of NFT Contract, contract should be ERC1155 or NFT standard
   */
  function putOnSale(
    uint8 _priceType,
    uint256 _price,
    uint256 _startTime,
    uint256 _endTime,
    uint256 _tokenId,
    uint8 _paymentMode,
    uint256 _amount,
    address _contractAddress
  ) public {
    uint8 _nftType = _getNFTType(_contractAddress);
    if (_amount > 0) {
      _transferNFT(msg.sender, address(this), _tokenId, _amount, _contractAddress, _nftType);
    } else {
      senderMustBeTokenOwner(_tokenId, _contractAddress);
    }

    require(activeBid[_contractAddress][_tokenId][msg.sender].bidder == address(0), "bid");

    TokenInfo storage info = tokenInfo[_contractAddress][_tokenId];
    if (info.owners.length == 0) {
      tokenInfo[_contractAddress][_tokenId] = TokenInfo(
        _tokenId,
        msg.sender,
        new address[](0),
        iMarketplaceSettings.getMarketplaceFeePercentage(),
        block.timestamp,
        _nftType
      );

      tokenOwnerInfo[_contractAddress][_tokenId][msg.sender] = TokenOwnerInfo(
        false,
        0,
        new uint256[](0),
        new uint256[](0),
        new address[](0),
        _amount
      );
    } else {
      tokenOwnerInfo[_contractAddress][_tokenId][msg.sender].tokenAmount =
        tokenOwnerInfo[_contractAddress][_tokenId][msg.sender].tokenAmount +
        _amount;
    }

    _setPrices(msg.sender, _priceType, _price, _startTime, _endTime, _tokenId, _paymentMode, _contractAddress);
    for (uint index; index < info.owners.length; index++) {
      //incase owner already exists
      if (tokenInfo[_contractAddress][_tokenId].owners[index] == msg.sender) return;
    }
    info.owners.push(msg.sender);
  }

  /**
   * @dev external function to send back token to owner from contract
   * @param _tokenId uint256 ID of the token
   * @param _amount token amount
   * @param _contractAddress address of NFT Contract, contract should be ERC1155 or NFT standard
   */
  function removeFromSale(
    uint256 _tokenId,
    uint256 _amount,
    address _contractAddress
  ) external {
    uint8 _nftType = _getNFTType(_contractAddress);

    require(activeBid[_contractAddress][_tokenId][msg.sender].bidder == address(0), "bid");
    require(_amount <= tokenInContract[_tokenId][msg.sender], "amount");
    _transferNFT(address(this), msg.sender, _tokenId, _amount, _contractAddress, _nftType);

    tokenInContract[_tokenId][msg.sender] = tokenInContract[_tokenId][msg.sender] - _amount;
    tokenOwnerInfo[_contractAddress][_tokenId][msg.sender].tokenAmount =
      tokenOwnerInfo[_contractAddress][_tokenId][msg.sender].tokenAmount -
      _amount;
  }

  /**
   * @dev external function to put on sale.
   * @param _priceType set the price type
   * @param _price price of the token
   * @param _startTime start time of bid, pass 0 of _priceType is not 1
   * @param _endTime end time of bid, pass 0 of _priceType is not 1
   * @param _owner owner of the token
   * @param _tokenId uint256 id of the token.
   * @param _paymentMode 0 for ETH/BNB, 1 for NAFT
   * @param _contractAddress address of NFT Contract, contract should be ERC1155 or NFT standard
   */
  function _setPrices(
    address _owner,
    uint8 _priceType,
    uint256 _price,
    uint256 _startTime,
    uint256 _endTime,
    uint256 _tokenId,
    uint8 _paymentMode,
    address _contractAddress
  ) public {
    if (_priceType == 0) {
      salePrice[_contractAddress][_tokenId][_owner] = SalePrice(payable(_owner), _price, _paymentMode);
    } else if (_priceType == 1 || _priceType == 2) {
      activeBid[_contractAddress][_tokenId][_owner] = ActiveBid(
        payable(_owner),
        tokenInfo[_contractAddress][_tokenId].serviceFee,
        _price,
        _paymentMode
      );
      activeBidRange[_contractAddress][_tokenId][_owner] = ActiveBidRange(_startTime, _endTime);
    }
    _setPrice(_price, _priceType, _tokenId, _owner, _contractAddress);
  }

  /**
   * @dev update price only from auction.
   * @param _price price of the token
   * @param _priceType 0 is for sale and 1 and 2 for auction
   * @param _tokenId uint256 id of the token.
   * @param _owner address of the token owner
   * @param _contractAddress address of NFT Contract, contract should be ERC1155 or NFT standard
   */
  function _setPrice(
    uint256 _price,
    uint8 _priceType,
    uint256 _tokenId,
    address _owner,
    address _contractAddress
  ) private {
    TokenOwnerInfo storage info = tokenOwnerInfo[_contractAddress][_tokenId][_owner];
    info.prices.push(_price);
    info.isForSale = true;
    info.priceType = _priceType;
  }

  /**
   * @dev update owner bids .
   * @param _bid bid Amount
   * @param _bidder bidder address
   * @param _tokenId uint256 id of the token.
   * @param _owner address of the token owner
   * @param _contractAddress address of NFT Contract, contract should be ERC1155 or NFT standard
   */
  function _setOwnerBid(
    uint256 _bid,
    address _bidder,
    uint256 _tokenId,
    address _owner,
    address _contractAddress
  ) private {
    TokenOwnerInfo storage info = tokenOwnerInfo[_contractAddress][_tokenId][_owner];
    info.bids.push(_bid);
    info.bidders.push(_bidder);
  }

  /////////////////////////////////////////////////////////////////////////
  // _resetTokenPrice
  /////////////////////////////////////////////////////////////////////////
  /**
   * @dev Internal function to set token price to 0 for a given contract.
   * @param _tokenId uin256 id of the token.
   * @param _owner address of the token owner
   * @param _contractAddress address of NFT Contract, contract should be ERC1155 or NFT standard
   */
  function _resetTokenPrice(
    uint256 _tokenId,
    address _owner,
    address _contractAddress
  ) internal {
    salePrice[_contractAddress][_tokenId][_owner] = SalePrice(payable(address(0)), 0, 0);
    _resetBid(_tokenId, _owner, _contractAddress);
    tokenOwnerInfo[_contractAddress][_tokenId][_owner].isForSale = false;
    // nafter.removeFromSale(_tokenId, _owner);
  }

  /////////////////////////////////////////////////////////////////////////
  // _refundBid
  /////////////////////////////////////////////////////////////////////////
  /**
   * @dev Internal function to return an existing bid on a token to the
   *      bidder and reset bid.
   * @param _tokenId uin256 id of the token.
   * @param _owner address of the token owner
   * @param _contractAddress address of NFT Contract, contract should be ERC1155 or NFT standard
   */
  function _refundBid(
    uint256 _tokenId,
    address _owner,
    address _contractAddress
  ) internal {
    ActiveBid memory currentBid = activeBid[_contractAddress][_tokenId][_owner];
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
    _resetBid(_tokenId, _owner, _contractAddress);
  }

  /////////////////////////////////////////////////////////////////////////
  // _resetBid
  /////////////////////////////////////////////////////////////////////////
  /**
   * @dev Internal function to reset bid by setting bidder and bid to 0.
   * @param _tokenId uin256 id of the token.
   * @param _owner address of the token owner
   * @param _contractAddress address of NFT Contract, contract should be ERC1155 or NFT standard
   */
  function _resetBid(
    uint256 _tokenId,
    address _owner,
    address _contractAddress
  ) internal {
    activeBid[_contractAddress][_tokenId][_owner] = ActiveBid(payable(address(0)), 0, 0, 0);
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
   * @param _contractAddress address of NFT Contract, contract should be ERC1155 or NFT standard
   */
  function _setBid(
    uint256 _amount,
    address payable _bidder,
    uint256 _tokenId,
    address _owner,
    uint8 _paymentMode,
    address _contractAddress
  ) internal {
    // Check bidder not 0 address.
    require(_bidder != address(0), "no 0 address");

    // Set bid.
    activeBid[_contractAddress][_tokenId][_owner] = ActiveBid(
      _bidder,
      tokenInfo[_contractAddress][_tokenId].serviceFee,
      _amount,
      _paymentMode
    );
    // add bid balance
    if (_paymentMode == 0) {
      bidBalance[_bidder] = feeConfig == 2 || feeConfig == 3
        ? bidBalance[_bidder].add(_amount.add(_amount.mul(tokenInfo[_contractAddress][_tokenId].serviceFee).div(100)))
        : bidBalance[_bidder].add(_amount);
    } else {
      nafterBidBalance[_bidder] = nafterBidBalance[_bidder].add(_amount);
    }
  }

  /**
   * @dev internal function to add external NFT to marketplace
   * @param _owner address of the token owner
   * @param _tokenId uint256 ID of the token
   * @param _amount token Amount
   */
  function _addTokenToNafterMarket(
    address _owner,
    uint256 _tokenId,
    uint256 _amount
  ) internal {
    tokenInContract[_tokenId][_owner] = tokenInContract[_tokenId][_owner] + _amount;
  }

  /**
   * @dev get interface type of contract address, return 0 for ERC1155 and 1 for ERC721
   */
  function _getNFTType(address _contractAddress) internal view returns (uint8) {
    bool interfaceType = _contractAddress.supportsInterface(IID_IERC1155);
    if (interfaceType == true) return 0;
    interfaceType = _contractAddress.supportsInterface(IID_IERC721);
    if (interfaceType == true) return 1;
    revert("wrong interface");
  }
}
