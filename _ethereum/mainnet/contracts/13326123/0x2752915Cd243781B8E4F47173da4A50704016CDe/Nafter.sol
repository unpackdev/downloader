// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

pragma experimental ABIEncoderV2;

import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./ERC1155Upgradeable.sol";
import "./draft-EIP712Upgradeable.sol";
import "./ECDSAUpgradeable.sol";
import "./INafter.sol";
import "./INafterMarketAuction.sol";
import "./IMarketplaceSettings.sol";
import "./INafterRoyaltyRegistry.sol";
import "./INafterTokenCreatorRegistry.sol";

/**
 * Nafter core contract.
 */

contract Nafter is
  Initializable,
  ERC1155Upgradeable,
  EIP712Upgradeable,
  OwnableUpgradeable,
  AccessControlUpgradeable,
  INafter
{
  struct TokenInfo {
    uint256 tokenId;
    address creator;
    uint256 tokenAmount;
    address[] owners;
    uint8 serviceFee;
    uint256 creationTime;
  }

  struct TokenOwnerInfo {
    bool isForSale;
    uint8 priceType; // 0 for fixed, 1 for Auction dates range, 2 for Auction Infinity
    uint256[] prices;
    uint256[] bids;
    address[] bidders;
  }

  // mapping of token info
  mapping(uint256 => TokenInfo) public tokenInfo;
  mapping(uint256 => mapping(address => TokenOwnerInfo)) public tokenOwnerInfo;

  mapping(uint256 => bool) public tokenIdsAvailable;

  uint256[] public tokenIds;
  uint256 public maxId;
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

  // market auction to set the price
  INafterMarketAuction public marketAuction;
  IMarketplaceSettings public marketplaceSettings;
  INafterRoyaltyRegistry public royaltyRegistry;
  INafterTokenCreatorRegistry public tokenCreatorRegistry;
  // Mapping from account to operator approvals
  mapping(address => mapping(address => bool)) private _operatorApprovals;

  // Event indicating metadata was updated.
  event AddNewToken(address user, uint256 tokenId);
  event DeleteTokens(address user, uint256 tokenId, uint256 amount);

  function __Nafter_init(string memory _uri) public initializer {
    __Ownable_init();
    __ERC1155_init(_uri);
    __AccessControl_init();
    __EIP712_init("NafterNFT", "1.1.0");
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC1155Upgradeable, AccessControlUpgradeable)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  /**
   * @dev See {IERC1155-setApprovalForAll}.
   */
  function setApprovalForAll(address operator, bool approved) public override {
    require(_msgSender() != operator, "Approval self");
    _operatorApprovals[_msgSender()][operator] = approved;
    emit ApprovalForAll(_msgSender(), operator, approved);
  }

  /**
   * @dev See {IERC1155-setApprovalForAll}. by NafterMarketAuction
   */
  function setApprovalForAllByNMA(
    address _creator,
    address _operator,
    bool _approved
  ) external override {
    require(_msgSender() == address(marketAuction), "nma");
    _operatorApprovals[_creator][_operator] = _approved;
  }

  /**
   * @dev See {IERC1155-isApprovedForAll}.
   */
  function isApprovedForAll(address account, address operator) public view override returns (bool) {
    return _operatorApprovals[account][operator];
  }

  /**
   * @dev Gets the creator of the token
   * @param _tokenId uint256 ID of the token
   * @return address of the creator
   */
  function creatorOfToken(uint256 _tokenId) external view override returns (address payable) {
    return payable(tokenInfo[_tokenId].creator);
  }

  /**
   * @dev Gets the token amount
   * @param _tokenId uint256 ID of the token
   */
  function getTokenAmount(uint256 _tokenId) external view returns (uint256) {
    return tokenInfo[_tokenId].tokenAmount;
  }

  /**
   * @dev Gets the owners
   * @param _tokenId uint256 ID of the token
   */
  function getOwners(uint256 _tokenId) external view override returns (address[] memory owners) {
    return tokenInfo[_tokenId].owners;
  }

  /**
   * @dev Gets the Service Fee
   * @param _tokenId uint256 ID of the token
   * @return get the service fee
   */
  function getServiceFee(uint256 _tokenId) external view override returns (uint8) {
    return tokenInfo[_tokenId].serviceFee;
  }

  /**
   * @dev Gets the creation time
   * @param _tokenId uint256 ID of the token
   */
  function getCreationTime(uint256 _tokenId) external view returns (uint256) {
    return tokenInfo[_tokenId].creationTime;
  }

  /**
   * @dev Gets the is for sale
   * @param _tokenId uint256 ID of the token
   * @param _owner address of the token owner
   */
  function getIsForSale(uint256 _tokenId, address _owner) external view override returns (bool) {
    return tokenOwnerInfo[_tokenId][_owner].isForSale;
  }

  /**
   * @dev Gets the price type
   * @param _tokenId uint256 ID of the token
   * @param _owner address of the token owner
   * @return get the price type
   */
  function getPriceType(uint256 _tokenId, address _owner) external view override returns (uint8) {
    return tokenOwnerInfo[_tokenId][_owner].priceType;
  }

  /**
   * @dev Gets the prices
   * @param _tokenId uint256 ID of the token
   * @param _owner address of the token owner
   */
  function getPrices(uint256 _tokenId, address _owner) external view returns (uint256[] memory prices) {
    return tokenOwnerInfo[_tokenId][_owner].prices;
  }

  /**
   * @dev Gets the bids
   * @param _tokenId uint256 ID of the token
   * @param _owner address of the token owner
   */
  function getBids(uint256 _tokenId, address _owner) external view returns (uint256[] memory bids) {
    return tokenOwnerInfo[_tokenId][_owner].bids;
  }

  /**
   * @dev Gets the bidders
   * @param _tokenId uint256 ID of the token
   * @param _owner address of the token owner
   */
  function getBidders(uint256 _tokenId, address _owner) external view returns (address[] memory bidders) {
    return tokenOwnerInfo[_tokenId][_owner].bidders;
  }

  /**
   * @dev get tokenIds length
   */
  function getTokenIdsLength() external view override returns (uint256) {
    return tokenIds.length;
  }

  /**
   * @dev get token Id
   * @param _index uint256 index
   */

  function getTokenId(uint256 _index) external view override returns (uint256) {
    return tokenIds[_index];
  }

  /**
   * @dev get owner tokens
   * @param _owner address of owner.
   */

  function getOwnerTokens(address _owner)
    public
    view
    returns (TokenInfo[] memory tokens, TokenOwnerInfo[] memory ownerInfo)
  {
    uint256 totalValues;
    //calculate totalValues
    for (uint256 i = 0; i < tokenIds.length; i++) {
      TokenInfo memory info = tokenInfo[tokenIds[i]];
      if (info.owners[info.owners.length - 1] == _owner) {
        totalValues++;
      }
    }

    TokenInfo[] memory values = new TokenInfo[](totalValues);
    TokenOwnerInfo[] memory valuesOwner = new TokenOwnerInfo[](totalValues);
    for (uint256 i = 0; i < tokenIds.length; i++) {
      uint256 tokenId = tokenIds[i];
      TokenInfo memory info = tokenInfo[tokenId];
      if (info.owners[info.owners.length - 1] == _owner) {
        values[i] = info;
        valuesOwner[i] = tokenOwnerInfo[tokenId][_owner];
      }
    }

    return (values, valuesOwner);
  }

  /**
   * @dev get token paging
   * @param _offset offset of the records.
   * @param _limit limits of the records.
   */
  function getTokensPaging(uint256 _offset, uint256 _limit)
    public
    view
    returns (
      TokenInfo[] memory tokens,
      uint256 nextOffset,
      uint256 total
    )
  {
    uint256 tokenInfoLength = tokenIds.length;
    if (_limit == 0) {
      _limit = 1;
    }

    if (_limit > tokenInfoLength - _offset) {
      _limit = tokenInfoLength - _offset;
    }

    TokenInfo[] memory values = new TokenInfo[](_limit);
    for (uint256 i = 0; i < _limit; i++) {
      uint256 tokenId = tokenIds[_offset + i];
      values[i] = tokenInfo[tokenId];
    }

    return (values, _offset + _limit, tokenInfoLength);
  }

  /**
   * @dev Checks that the token was owned by the sender.
   * @param _tokenId uint256 ID of the token.
   */
  function _onlyTokenOwner(uint256 _tokenId) internal view {
    uint256 balance = balanceOf(msg.sender, _tokenId);
    require(balance > 0, "owner");
  }

  /**
   * @dev Checks that the token was created by the sender.
   * @param _tokenId uint256 ID of the token.
   */
  function _onlyTokenCreator(uint256 _tokenId) internal view {
    address creator = tokenInfo[_tokenId].creator;
    require(creator == msg.sender, "creator");
  }

  /**
   * @dev restore data from old contract, only call by owner
   * @param _oldAddress address of old contract.
   * @param _startIndex start index of array
   * @param _endIndex end index of array
   */
  function restore(
    address _oldAddress,
    uint256 _startIndex,
    uint256 _endIndex
  ) external onlyOwner {
    Nafter oldContract = Nafter(_oldAddress);

    for (uint256 i = _startIndex; i < _endIndex; i++) {
      uint256 tokenId = oldContract.getTokenId(i);
      tokenIds.push(tokenId);
      tokenInfo[tokenId] = TokenInfo(
        tokenId,
        oldContract.creatorOfToken(tokenId),
        oldContract.getTokenAmount(tokenId),
        oldContract.getOwners(tokenId),
        oldContract.getServiceFee(tokenId),
        oldContract.getCreationTime(tokenId)
      );

      address[] memory owners = tokenInfo[tokenId].owners;
      for (uint256 j = 0; j < owners.length; j++) {
        address owner = owners[j];
        tokenOwnerInfo[tokenId][owner] = TokenOwnerInfo(
          oldContract.getIsForSale(tokenId, owner),
          oldContract.getPriceType(tokenId, owner),
          oldContract.getPrices(tokenId, owner),
          oldContract.getBids(tokenId, owner),
          oldContract.getBidders(tokenId, owner)
        );

        uint256 ownerBalance = oldContract.balanceOf(owner, tokenId);
        if (ownerBalance > 0) {
          _mint(owner, tokenId, ownerBalance, "");
        }
      }
      tokenIdsAvailable[tokenId] = true;
    }
    maxId = oldContract.maxId();
  }

  /**
   * @dev update or mint token Amount only from token creator.
   * @param _tokenAmount token Amount
   * @param _tokenId uint256 id of the token.
   */
  function setTokenAmount(uint256 _tokenAmount, uint256 _tokenId) external {
    _onlyTokenCreator(_tokenId);
    tokenInfo[_tokenId].tokenAmount = tokenInfo[_tokenId].tokenAmount + _tokenAmount;
    _mint(msg.sender, _tokenId, _tokenAmount, "");
  }

  /**
   * @dev update is for sale only from token Owner.
   * @param _isForSale is For Sale
   * @param _tokenId uint256 id of the token.
   */
  function setIsForSale(bool _isForSale, uint256 _tokenId) external {
    _onlyTokenOwner(_tokenId);
    tokenOwnerInfo[_tokenId][msg.sender].isForSale = _isForSale;
  }

  /**
   * @dev update is for sale only from token Owner.
   * @param _priceType set the price type
   * @param _price price of the token
   * @param _startTime start time of bid, pass 0 of _priceType is not 1
   * @param _endTime end time of bid, pass 0 of _priceType is not 1
   * @param _tokenId uint256 id of the token.
   * @param _owner owner of the token
   * @param _paymentMode 0 for ETH/BNB, 1 for NAFT
   */
  function putOnSale(
    uint8 _priceType,
    uint256 _price,
    uint256 _startTime,
    uint256 _endTime,
    uint256 _tokenId,
    address _owner,
    uint8 _paymentMode
  ) external {
    _onlyTokenOwner(_tokenId);
    _putOnSale(_owner, _priceType, _price, _startTime, _endTime, _tokenId, _paymentMode);
  }

  /**
   * @dev remove token from sale
   * @param _tokenId uint256 id of the token.
   * @param _owner owner of the token
   */
  function removeFromSale(uint256 _tokenId, address _owner) external override {
    uint256 balance = balanceOf(msg.sender, _tokenId);
    require(balance > 0 || msg.sender == address(marketAuction), "nma");

    tokenOwnerInfo[_tokenId][_owner].isForSale = false;
  }

  /**
   * @dev update price type from token Owner.
   * @param _priceType price type
   * @param _tokenId uint256 id of the token.
   */
  function setPriceType(uint8 _priceType, uint256 _tokenId) external {
    _onlyTokenOwner(_tokenId);
    tokenOwnerInfo[_tokenId][msg.sender].priceType = _priceType;
  }

  /**
   * @dev set marketAuction address to set the sale price
   * @param _marketAuction address of market auction.
   * @param _marketplaceSettings address of market auction.
   */
  function setMarketAddresses(
    address _marketAuction,
    address _marketplaceSettings,
    address _tokenCreatorRegistry,
    address _royaltyRegistry
  ) external onlyOwner {
    marketAuction = INafterMarketAuction(_marketAuction);
    marketplaceSettings = IMarketplaceSettings(_marketplaceSettings);
    tokenCreatorRegistry = INafterTokenCreatorRegistry(_tokenCreatorRegistry);
    royaltyRegistry = INafterRoyaltyRegistry(_royaltyRegistry);
  }

  /**
   * @dev update price only from auction.
   * @param _price price of the token
   * @param _tokenId uint256 id of the token.
   * @param _owner address of the token owner
   */
  function setPrice(
    uint256 _price,
    uint256 _tokenId,
    address _owner
  ) external override {
    require(msg.sender == address(marketAuction), "nma");
    TokenOwnerInfo storage info = tokenOwnerInfo[_tokenId][_owner];
    info.prices.push(_price);
  }

  /**
   * @dev update bids only from auction.
   * @param _bid bid Amount
   * @param _bidder bidder address
   * @param _tokenId uint256 id of the token.
   * @param _owner address of the token owner
   */
  function setBid(
    uint256 _bid,
    address _bidder,
    uint256 _tokenId,
    address _owner
  ) external override {
    require(msg.sender == address(marketAuction), "nma");
    TokenOwnerInfo storage info = tokenOwnerInfo[_tokenId][_owner];
    info.bids.push(_bid);
    info.bidders.push(_bidder);
  }

  /**
   * @dev add token and set the price.
   * @param _price price of the item.
   * @param _tokenAmount total token amount available
   * @param _isForSale if is for sale
   * @param _priceType 0 is for fixed, 1 is for Auction Time bound, 2 is for Auction Infinite
   * @param _royaltyPercentage royalty percentage of creator
   * @param _startTime start time of bid, pass 0 of _priceType is not 1
   * @param _endTime end time of bid, pass 0 of _priceType is not 1
   * @param _tokenId uint256 ID of the token.
   * @param _paymentMode 0 for ETH/BNB, 1 for NAFT
   */
  function addNewTokenAndSetThePriceWithId(
    uint256 _tokenAmount,
    bool _isForSale,
    uint256 _price,
    uint8 _priceType,
    uint8 _royaltyPercentage,
    uint256 _startTime,
    uint256 _endTime,
    uint256 _tokenId,
    uint8 _paymentMode
  ) public {
    uint256 tokenId = _createTokenWithId(
      msg.sender,
      _tokenAmount,
      _isForSale,
      _price,
      _priceType,
      _royaltyPercentage,
      _tokenId,
      msg.sender
    );
    _putOnSale(msg.sender, _priceType, _price, _startTime, _endTime, tokenId, _paymentMode);

    emit AddNewToken(msg.sender, tokenId);
  }

  /**
   * @dev add token and set the price.
   * @param _price price of the item.
   * @param _tokenAmount total token amount available
   * @param _isForSale if is for sale
   * @param _priceType 0 is for fixed, 1 is for Auction Time bound, 2 is for Auction Infinite
   * @param _royaltyPercentage royalty percentage of creator
   * @param _tokenId uint256 ID of the token.
   * @param _creator address of the creator
   * @param _minter address of minter
   */
  function addNewTokenAndSetThePriceWithIdAndMinter(
    uint256 _tokenAmount,
    bool _isForSale,
    uint256 _price,
    uint8 _priceType,
    uint8 _royaltyPercentage,
    uint256 _tokenId,
    address _creator,
    address _minter
  ) external override onlyRole(MINTER_ROLE) {
    _createTokenWithId(_creator, _tokenAmount, _isForSale, _price, _priceType, _royaltyPercentage, _tokenId, _minter);
  }

  /**
   * @dev Deletes the token with the provided ID.
   * @param _tokenId uint256 ID of the token.
   * @param _amount amount of the token to delete
   */
  function deleteToken(uint256 _tokenId, uint256 _amount) public {
    _onlyTokenOwner(_tokenId);
    bool activeBid = marketAuction.hasTokenActiveBid(_tokenId, msg.sender);
    uint256 balance = balanceOf(msg.sender, _tokenId);
    //2
    if (activeBid == true) require(balance - _amount > 0, "active bid");
    _burn(msg.sender, _tokenId, _amount);
    DeleteTokens(msg.sender, _tokenId, _amount);
  }

  /**
   * @dev internal function to put on sale.
   * @param _priceType set the price type
   * @param _price price of the token
   * @param _startTime start time of bid, pass 0 of _priceType is not 1
   * @param _endTime end time of bid, pass 0 of _priceType is not 1
   * @param _owner owner of the token
   * @param _tokenId uint256 id of the token.
   * @param _paymentMode 0 for ETH/BNB, 1 for NAFT
   */
  function _putOnSale(
    address _owner,
    uint8 _priceType,
    uint256 _price,
    uint256 _startTime,
    uint256 _endTime,
    uint256 _tokenId,
    uint8 _paymentMode
  ) internal {
    require(marketAuction.hasTokenActiveBid(_tokenId, msg.sender) == false, "bid");
    if (_priceType == 0) {
      marketAuction.setSalePrice(_tokenId, _price, _owner, _paymentMode);
    }
    if (_priceType == 1 || _priceType == 2) {
      marketAuction.setInitialBidPriceWithRange(_price, _startTime, _endTime, _owner, _tokenId, _paymentMode);
    }
    tokenOwnerInfo[_tokenId][_owner].isForSale = true;
    tokenOwnerInfo[_tokenId][_owner].priceType = _priceType;
  }

  /**
   * @dev redeem to add a new token.
   * @param _creator address of the creator of the token.
   * @param _tokenAmount total token amount available
   * @param _isForSale if is for sale
   * @param _price price of the token, 0 is for not set the price.
   * @param _priceType 0 is for fixed, 1 is for Auction Time bound, 2 is for Auction Infinite
   * @param _royaltyPercentage royalty percentage of creator
   * @param _startTime start time of bid, pass 0 of _priceType is not 1
   * @param _endTime end time of bid, pass 0 of _priceType is not 1
   * @param _tokenId uint256 token id
   * @param _paymentMode 0 for ETH/BNB, 1 for NAFT
   * @param _signature data signature to return account information
   */
  function verify(
    address _creator,
    uint256 _tokenAmount,
    bool _isForSale,
    uint256 _price,
    uint8 _priceType,
    uint8 _royaltyPercentage,
    uint256 _startTime,
    uint256 _endTime,
    uint256 _tokenId,
    uint8 _paymentMode,
    bytes calldata _signature
  ) external view override {
    require(tokenIdsAvailable[_tokenId] == false, "id exist");
    require(
      ECDSAUpgradeable.recover(
        _hash(
          _creator,
          _tokenAmount,
          _isForSale,
          _price,
          _priceType,
          _royaltyPercentage,
          _startTime,
          _endTime,
          _tokenId,
          _paymentMode
        ),
        _signature
      ) == _creator,
      "Invalid signature"
    );
  }

  /**
   * @dev Sets uri of tokens.
   *
   * Requirements:
   *
   * @param _uri new uri .
   */
  function setURI(string memory _uri) external onlyOwner {
    _setURI(_uri);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) public virtual override {
    //transfer case
    if (msg.sender != address(marketAuction)) {
      bool activeBid = marketAuction.hasTokenActiveBid(id, from);
      if (activeBid == true) require(balanceOf(from, id) - amount > 0, "active bid");
    }
    super.safeTransferFrom(from, to, id, amount, data);
    for (uint256 i = 0; i < tokenInfo[id].owners.length; i++) {
      if (tokenInfo[id].owners[i] == to)
        //incase owner already exists
        return;
    }
    tokenInfo[id].owners.push(to);
  }

  /**
   * @dev Internal function creating a new token.
   * @param _creator address of the creator of the token.
   * @param _tokenAmount total token amount available
   * @param _isForSale if is for sale
   * @param _price price of the token, 0 is for not set the price.
   * @param _priceType 0 is for fixed, 1 is for Auction Time bound, 2 is for Auction Infinite
   * @param _royaltyPercentage royalty percentage of creator
   * @param _tokenId uint256 token id
   */
  function _createTokenWithId(
    address _creator,
    uint256 _tokenAmount,
    bool _isForSale,
    uint256 _price,
    uint8 _priceType,
    uint8 _royaltyPercentage,
    uint256 _tokenId,
    address _minter
  ) internal returns (uint256) {
    require(tokenIdsAvailable[_tokenId] == false, "id exist");

    tokenIdsAvailable[_tokenId] = true;
    tokenIds.push(_tokenId);

    maxId = maxId > _tokenId ? maxId : _tokenId;

    _mint(_minter, _tokenId, _tokenAmount, "");

    tokenInfo[_tokenId] = TokenInfo(
      _tokenId,
      _creator,
      _tokenAmount,
      new address[](0),
      marketplaceSettings.getMarketplaceFeePercentage(),
      block.timestamp
    );

    tokenInfo[_tokenId].owners.push(_creator);

    tokenOwnerInfo[_tokenId][_creator] = TokenOwnerInfo(
      _isForSale,
      _priceType,
      new uint256[](0),
      new uint256[](0),
      new address[](0)
    );
    tokenOwnerInfo[_tokenId][_creator].prices.push(_price);

    royaltyRegistry.setPercentageForTokenRoyalty(_tokenId, _royaltyPercentage);
    tokenCreatorRegistry.setTokenCreator(_tokenId, payable(_creator));

    return _tokenId;
  }

  /**
   * @dev calculate the hash internal function
   * @param _creator address of the creator of the token.
   * @param _tokenAmount total token amount available
   * @param _isForSale if is for sale
   * @param _price price of the token, 0 is for not set the price.
   * @param _priceType 0 is for fixed, 1 is for Auction Time bound, 2 is for Auction Infinite
   * @param _royaltyPercentage royalty percentage of creator
   * @param _startTime start time of bid, pass 0 of _priceType is not 1
   * @param _endTime end time of bid, pass 0 of _priceType is not 1
   * @param _tokenId uint256 token id
   * @param _paymentMode 0 for ETH/BNB, 1 for NAFT
   */
  function _hash(
    address _creator,
    uint256 _tokenAmount,
    bool _isForSale,
    uint256 _price,
    uint8 _priceType,
    uint8 _royaltyPercentage,
    uint256 _startTime,
    uint256 _endTime,
    uint256 _tokenId,
    uint8 _paymentMode
  ) internal view returns (bytes32) {
    return
      _hashTypedDataV4(
        keccak256(
          abi.encode(
            keccak256(
              "NafterNFT(address _creator,uint256 _tokenAmount,bool _isForSale,uint256 _price,uint8 _priceType,uint8 _royaltyPercentage,uint256 _startTime,uint256 _endTime,uint256 _tokenId,uint8 _paymentMode)"
            ),
            _creator,
            _tokenAmount,
            _isForSale,
            _price,
            _priceType,
            _royaltyPercentage,
            _startTime,
            _endTime,
            _tokenId,
            _paymentMode
          )
        )
      );
  }
}
