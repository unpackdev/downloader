//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./WTFERC721.sol";
import "./IERC721.sol";
import "./Ownable.sol";
import "./CantBeEvil.sol";
import "./IDudesAuctionHouse.sol";

/**
 * @title Distracted Dudes
 * @notice What distracts you?? Released CC0; onchain verifiable via a16z Cant Be Evil license
 */
contract DistractedDudes is WTFERC721, Ownable, CantBeEvil(LicenseVersion.PUBLIC) {
  /* ============ Variables ============ */

  /// @notice NFT price in ETH
  uint256 public price;

  /// @notice mfer contract address
  IERC721 public immutable mferAddress;

  /// @notice pfer contract address
  IERC721 public immutable pferAddress;

  /// @notice sproto contract address
  IERC721 public immutable sprotoAddress;

  /// @notice Max number of non 1/1 NFTs available in this collection
  uint256 public immutable maxNFT;

  /// @notice Max number of 1/1 NFTs available in this collection
  uint256 public immutable max1o1NFT;

  /// @notice Max number of NFTs that can be public minted in a single transaction
  uint256 public immutable maxPublicMint;

  /// @notice Timestamp of when public sale starts
  uint256 public saleStartTimestamp;

  /// @notice Timestamp of when presale starts
  uint256 public presaleStartTimestamp;

  /// @notice Total current supply of non 1/1 NFTs
  uint256 public dudeCurrentSupply;

  /// @notice Total current supply of 1/1 NFTs
  uint256 public dude1o1CurrentSupply;

  /// @notice NFT tokens base URI
  string public baseURI;

  /// @notice Map to track what access token ids were used to mint dudes
  mapping(IERC721 => mapping(uint256 => bool)) public accessTokenUsedToMint;

  IDudesAuctionHouse public auctionHouse;

  /// @notice Flag for if NFT metadata is revealed
  bool private revealed = false;

  string private constant PRE_REVEAL_URI = "ipfs://QmP1paK6cVekPPCvMGH6JHKVu1QYu4tMBZDqbYs5LWoM3A";

  address payable private mainDude;

  /* ============ Structs ============ */
  // Enum for type of access NFT
  enum AccessNFTType {
    MFER,
    PFER,
    SPROTO
  }

  struct ContractData {
    uint256 price;
    IERC721 mferAddress;
    IERC721 pferAddress;
    IERC721 sprotoAddress;
    uint256 maxNFT;
    uint256 max1o1NFT;
    uint256 maxPublicMint;
    uint256 saleStartTimestamp;
    uint256 presaleStartTimestamp;
    address payable mainDude;
  }

  /* ============ Constructor ============ */

  /**
   * @notice Initializes the NFT contract
   * @param _name NFT collection name
   * @param _symbol NFT collection symbol
   * @param _contractData struct containing contract data
   *          price - price per dude
   *          mferAddress - mfer contract address
   *          pferAddress - pfer contract address
   *          sprotoAddress - sproto contract address
   *          maxNFT - max number of non 1/1 NFTs available in this collection
   *          max1o1NFT - max number of 1/1 NFTs available in this collection
   *          maxPublicMint - max number of NFTs that can be public minted
   *          saleStartTimestamp - timestamp of when public sale starts
   *          presaleStartTimestamp - timestamp of when early access presale starts
   *          mainDude - main dude address
   */
  constructor(
    string memory _name,
    string memory _symbol,
    ContractData memory _contractData
  ) WTFERC721(_name, _symbol) {
    require(_contractData.maxNFT > 0, "Dudes:max-nft-gt-zero");
    require(_contractData.max1o1NFT > 0, "Dudes:max-1o1-gt-zero");
    require(_contractData.maxPublicMint > 0, "Dudes:max-mint-gt-zero");
    require(_contractData.presaleStartTimestamp > block.timestamp, "Dudes:presale-start-gt-now");
    require(_contractData.saleStartTimestamp > block.timestamp, "Dudes:sale-start-gt-now");
    require(_contractData.mainDude != address(0), "Dudes:main-dude-not-zero-address");

    price = _contractData.price;
    mferAddress = _contractData.mferAddress;
    pferAddress = _contractData.pferAddress;
    sprotoAddress = _contractData.sprotoAddress;
    maxNFT = _contractData.maxNFT;
    max1o1NFT = _contractData.max1o1NFT;
    maxPublicMint = _contractData.maxPublicMint;
    saleStartTimestamp = _contractData.saleStartTimestamp;
    presaleStartTimestamp = _contractData.presaleStartTimestamp;
    mainDude = _contractData.mainDude;
  }

  modifier onlyAuctionHouse() {
    require(msg.sender != address(0) && msg.sender == address(auctionHouse), "Dudes:caller-is-not-auction-house");
    _;
  }

  /* ============ External Functions ============ */

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(CantBeEvil, WTFERC721)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  function totalSupply() external view returns (uint256) {
    return dudeCurrentSupply + dude1o1CurrentSupply - balanceOf(address(0));
  }

  /**
   * @notice Returns true is public sale is live.
   */
  function isPublicSaleActive() external view returns (bool) {
    return _isPublicSaleActive();
  }

  /**
   * @notice Returns true if mfers can mint.
   */
  function isPremintActive() external view returns (bool) {
    return _isPremintActive();
  }

  /**
   * @notice Override: returns token uri or static reveal uri if reveal is not active
   */
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    if (revealed) {
      return super.tokenURI(tokenId);
    } else {
      return PRE_REVEAL_URI;
    }
  }

  /**
   * @notice Returns true if the specific access token has been used to mint a dude
   */
  function isAccessTokenUsed(address _accessTokenAddress, uint256 _tokenId)
    external
    view
    returns (bool)
  {
    return _isAccessTokenUsed(_accessTokenAddress, _tokenId);
  }

  /**
   * @notice set reveal state to true
   * no way to set reveal back to false riskaay
   */
  function setRevealed() external onlyOwner {
    revealed = true;
  }

  function setPrice(uint256 _price) external onlyOwner {
    price = _price;
  }

  function setMainDude(address payable _mainDude) external onlyOwner {
    mainDude = _mainDude;
  }

  function setAuctionHouse(IDudesAuctionHouse _auctionHouse) external onlyOwner {
    auctionHouse = _auctionHouse;
  }

  /**
   * @notice Mints a new number of dudes at a 1:1 ratio of mfer/pfer/sproto.
   * @param _accessTokenIds list of mfer/pfer/sproto token ids that the sender holds to mint dudes
   * @param _accessNFTType type of access NFT from AccessNFTType enum - 0 for mfer, 1 for pfer, 2 for sproto
   * @dev be aware that even if one of the access token ids is not valid, the whole transaction will fail
   */
  function premint(uint256[] calldata _accessTokenIds, uint8 _accessNFTType) external payable {
    require(_isPremintActive(), "Dudes:premint-not-active");
    require(!_isPublicSaleActive(), "Dudes:premint-is-over");
    uint256 numberOfTokens = _accessTokenIds.length;
    require(numberOfTokens > 0, "Dudes:premint-ids-gt-zero");

    // set erc721 contract address based on accessNFTType
    IERC721 accessNFTAddress;
    if (_accessNFTType == uint8(AccessNFTType.MFER)) {
      accessNFTAddress = mferAddress;
    } else if (_accessNFTType == uint8(AccessNFTType.PFER)) {
      accessNFTAddress = pferAddress;
    } else if (_accessNFTType == uint8(AccessNFTType.SPROTO)) {
      accessNFTAddress = sprotoAddress;
    } else {
      revert("Dudes:invalid-access-nft-type");
    }

    require(accessNFTAddress.balanceOf(msg.sender) >= numberOfTokens, "Dudes:not-enough-tokens");

    uint256 _totalSupply = dudeCurrentSupply;
    require(_totalSupply + numberOfTokens <= maxNFT, "Dudes:premint-sold-out");

    // loop through the list of access tokens
    // check that the msg.sender owns the token
    // check that the token has not been used to mint a dude
    // if all checks pass, mint a dude and mark the token as used

    for (uint256 i = 0; i < numberOfTokens; i++) {
      uint256 accessTokenId = _accessTokenIds[i];
      require(accessNFTAddress.ownerOf(accessTokenId) == msg.sender, "Dudes:premint-not-owner");
      require(
        accessTokenUsedToMint[accessNFTAddress][accessTokenId] == false,
        "Dudes:premint-already-used"
      );
      uint256 mintTokenId = _totalSupply + i;
      accessTokenUsedToMint[accessNFTAddress][accessTokenId] = true;
      _safeMint(msg.sender, mintTokenId);
    }

    dudeCurrentSupply += numberOfTokens;
  }

  /**
   * @notice Mints a new number of dudes.
   * @param _numberOfTokens Number of dudes to mint
   */
  function mintDudes(uint256 _numberOfTokens) external payable {
    require(_isPublicSaleActive(), "Dudes:sale-inactive");

    require(_numberOfTokens > 0, "Dudes:wtf");

    uint256 _totalSupply = dudeCurrentSupply;

    require(_totalSupply + _numberOfTokens <= maxNFT, "Dudes:sold-out");
    require(_numberOfTokens <= maxPublicMint, "Dudes:exceeds-max-mint-per-tx");

    uint256 totalCost = _numberOfTokens * price;
    require(msg.value >= totalCost, "Dudes:insufficient-funds");

    dudeCurrentSupply += _numberOfTokens;

    for (uint256 i; i < _numberOfTokens; i++) {
      uint256 _mintIndex = _totalSupply + i;
      _safeMint(msg.sender, _mintIndex);
    }
  }

  /**
   * @notice Set NFT tokens base URI
   * @dev This function is only callable by the owner of the contract.
   * @param baseURI_ NFT tokens base URI
   */
  function setBaseURI(string memory baseURI_) external onlyOwner {
    baseURI = baseURI_;
  }

  /**
   * @notice Withdraw ETH from the contract.
   * @dev This function can be called by anyone but hardcode to withdraw to only specific address.
   */
  function withdraw() external {
    uint256 _amount = address(this).balance;
    require(_amount > 0, "Dudes:withdraw-amount-gt-zero");

    (bool _success, ) = mainDude.call{ value: _amount }("");

    require(_success, "Dudes:failed-to-withdraw-eth");
  }

  receive() external payable {}

  /* ============ Internal Functions ============ */

  function _isPublicSaleActive() internal view returns (bool) {
    return saleStartTimestamp < block.timestamp;
  }

  function _isPremintActive() internal view returns (bool) {
    return presaleStartTimestamp < block.timestamp;
  }

  function _isAccessTokenUsed(address _accessTokenAddress, uint256 _tokenId)
    internal
    view
    returns (bool)
  {
    return accessTokenUsedToMint[IERC721(_accessTokenAddress)][_tokenId];
  }

  /**
   * @notice Set NFT base URI.
   * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
   * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
   * by default, can be overridden in child contracts.
   * @return NFT tokens base URI
   */
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override {
    if (address(auctionHouse) != address(0)) {
      // do not allow transfers of dudes out for the current auction winner
      IDudesAuctionHouse.Auction memory _auction = auctionHouse.getActiveAuction();
      if (_auction.bidder != address(0)) {
        if (!_auction.settled) {
          require(_auction.bidder != from, "Dudes:transfer-auction-bidder");
        }
      }
    }
  }

  /* ============ Auction House Functions ============ */

  /**
   * @notice Get the next 1 of 1 dude token id.
   * @dev the 1 of 1 token ids will start at the non 1 of 1 max supply for the collection. Since token ids are zero indexed,
   *  the first token id of the 1 of 1s will be maxNFT.
   * @return dudeId The next 1 of 1 dude token id or 0 if there are no more dudes for auction
   */
  function getDudeForAuction() external view returns (uint256 dudeId) {
    if (dude1o1CurrentSupply < max1o1NFT) {
      dudeId = maxNFT + dude1o1CurrentSupply;
    } else {
      dudeId = 0;
    }
  }

  function mintAuctionDude(address _winner, uint256 _dudeId) external onlyAuctionHouse {
    dude1o1CurrentSupply++;
    _safeMint(_winner, _dudeId);
  }

  function burnByAuction(uint256 _dudeId) external onlyAuctionHouse {
    _burn(_dudeId);
  }
}
