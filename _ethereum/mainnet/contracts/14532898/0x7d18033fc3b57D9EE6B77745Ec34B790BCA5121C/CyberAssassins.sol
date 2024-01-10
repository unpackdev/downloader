// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./Counters.sol";
import "./MerkleProof.sol";
import "./SafeMath.sol";
import "./PaymentSplitter.sol";
import "./ReentrancyGuard.sol";

contract CyberAssassins is ERC721, ERC721Enumerable, ERC721Burnable, Ownable, PaymentSplitter, ReentrancyGuard {
  using Strings for string;
  using Counters for Counters.Counter;
  using SafeMath for uint256;

  uint256 public constant MAX_REGULAR_TOKENS = 4000;
  uint256 public constant MAX_SUPER_TOKENS = 2000;
  uint256 public constant MAX_ULTIMATE_TOKENS = 1300;
  uint256 private constant REGULAR_START_AT = 55;
  uint256 private constant SUPER_START_AT = 4025;
  uint256 private constant ULTIMATE_START_AT = 6012;

  uint256 public PRICE = 0.15 ether;
  uint256 public constant WHITELISTONEPRICE = 0.1 ether;
  uint256 public constant WHITELISTTWOPRICE = 0.12 ether;
  uint256 public WHITELISTMAXMINT = 5;
  string public baseTokenURI;
  bool private PAUSE = true;
  bool private SUPERMINTPAUSE = true;
  bool private ULTIMATEMINTPAUSE = true;
  bool private WHITELISTONEPAUSE = true;
  bool private WHITELISTTWOPAUSE = true;
  bool private isReserved = false;

  bytes32 internal whitelistOneMerkleRoot;
  bytes32 internal whitelistTwoMerkleRoot;

  address[] private _creators = [
                                    0x20E84d35D6c1fC7b945AF47D1F027939c9AD55BB, // Crypto Assassin
                                    0x5A3293DaCa51715c6D1D4a99f99b6A9E336054Fa, // NFTstothemetaverse
                                    0xEB3B6049B103FADf19E72557E96d4c23962438Cb, // Topsniper496
                                    0xddAb02FE9F645cfF986a80E88118732d8E9B557e, // Rabbit
                                    0x8334A9855FcFc64ece634E0223c5faA4A056E299, // Tariq
                                    0x4F4f15F1C86064B6ECB4C4a91A82E08A5Cd9FB41  // Company
                                ];
  uint256[] private _shares = [1, 1, 1, 1, 1, 1];

  /**
   * @dev The tracker of assassins (Regular, Super, Ultimate)
   */
  Counters.Counter private _tokenIdRegularTracker;
  Counters.Counter private _tokenIdSuperTracker;
  Counters.Counter private _tokenIdUltimateTracker;


  /**
   * @dev The tracker of assassins (Regular, Super, Ultimate) for teams and giveaways
   */
  Counters.Counter private _tokenIdRegularTrackerTeam;
  Counters.Counter private _tokenIdSuperTrackerTeam;
  Counters.Counter private _tokenIdUltimateTrackerTeam;

  /**
   * @dev The count of minted assassins (Regular, Super, Ultimate)
   */
  uint256 private _regularTokenCounter;
  uint256 private _superTokenCounter;
  uint256 private _ultimateTokenCounter;

  /**
   * @dev The whitelist
   */
  mapping(address => uint256) private _whitelistClaimed;

  event PauseEvent(bool pause);
  event SuperMintPauseEvent(bool pause);
  event UltimateMintPauseEvent(bool pause);
  event WhitelistPauseEvent(bool pause);
  event welcomeToAssassin(uint256 indexed id);

  constructor() ERC721("Cyber Assassins", "CASS") PaymentSplitter(_creators, _shares) {
  }

  /**
   * @dev Throws if save is not active.
   */
  modifier saleIsOpen() {
    require(!PAUSE, "Sale must be active to mint");
    _;
  }

  /**
   * @dev Throws if save is not active for Super.
   */
  modifier saleIsOpenForSuper() {
    require(!PAUSE, "Super Assassins sale must be active to mint");
    _;
  }

  /**
   * @dev Throws if save is not active for Ultimate.
   */
  modifier saleIsOpenForUltimate() {
    require(!PAUSE, "Ultimate Assassins sale must be active to mint");
    _;
  }

  /**
   * @dev Throws if merkle is not valid.
   */
  modifier saleIsOpenForWhitelist(bytes32[] memory merkleProof, uint256 whitelistType) {
    bytes32 merkleRoot;
    bool whitelistPause;
    if (whitelistType == 0) {
      // Phase 1 Presale
      merkleRoot = whitelistOneMerkleRoot;
      whitelistPause = WHITELISTONEPAUSE;
    } else if (whitelistType == 1) {
      // Phase 2 Presale
      merkleRoot = whitelistTwoMerkleRoot;
      whitelistPause = WHITELISTTWOPAUSE;
    }
    else {
      merkleRoot = 0;
      whitelistPause = false;
    }

    require(!whitelistPause, "Sale for whitelist must be active to mint");

    require(
        MerkleProof.verify(
            merkleProof,
            merkleRoot,
            keccak256(abi.encodePacked(_msgSender()))
        ),
        "Address does not exist in list"
    );
    _;
}

  function reserveAssassins() external onlyOwner nonReentrant {
    require(!isReserved, "Already reserved");

    // Teams
    uint256 tokenId;
    for (uint256 i = 0; i < _creators.length - 1; i++) {
      address wallet = _creators[i];
      uint256 k;

      // Regular Assassins
      for (k = 0; k < 5; k++) {
        // Increase tracker and counter of regular assassin
        _tokenIdRegularTrackerTeam.increment();
        _regularTokenCounter += 1;

        // Mint regular assassin
        tokenId = _tokenIdRegularTrackerTeam.current();
        _safeMint(wallet, tokenId);
      }

      // Super Assassins
      for (k = 0; k < 2; k++) {
        // Increase tracker and counter of super assassin
        _tokenIdSuperTrackerTeam.increment();
        _superTokenCounter += 1;

        // Mint super assassin
        tokenId = _tokenIdSuperTrackerTeam.current() + 12000;
        _safeMint(wallet, tokenId);
      }

      // Ultimate Assassins
      // Increase tracker and counter of ultimate assassin
      _tokenIdUltimateTrackerTeam.increment();
      _ultimateTokenCounter += 1;

      // Mint ultimate assassin
      tokenId = _tokenIdUltimateTrackerTeam.current() + 18000;
      _safeMint(wallet, tokenId);
    }

    // Giveaways
    _regularTokenCounter += 2;
    _tokenIdRegularTrackerTeam.increment();
    tokenId = _tokenIdRegularTrackerTeam.current();
    _safeMint(_creators[5], tokenId);
    _tokenIdRegularTrackerTeam.increment();
    tokenId = _tokenIdRegularTrackerTeam.current();
    _safeMint(_creators[5], tokenId);

    isReserved = true;
  }

  function sendRegularGiveaways(address _to, uint256 _count) external onlyOwner {
    require(isReserved, "Not reserve yet");

    for (uint256 i = 0; i < _count; i++) {
      // Increase tracker and counter of regular assassin
      _tokenIdRegularTrackerTeam.increment();
      _regularTokenCounter += 1;

      // Mint regular assassin
      uint256 tokenId = _tokenIdRegularTrackerTeam.current();
      _safeMint(_to, tokenId);
    }
  }

  function sendSuperGiveaways(address _to, uint256 _count) external onlyOwner {
    require(isReserved, "Not reserve yet");
    for (uint256 i = 0; i < _count; i++) {
      // Increase tracker and counter of super assassin
      _tokenIdSuperTrackerTeam.increment();
      _superTokenCounter += 1;

      // Mint super assassin
      uint256 tokenId = _tokenIdSuperTrackerTeam.current() + 12000;
      _safeMint(_to, tokenId);
    }
  }

  function sendUltimateGiveaways(address _to, uint256 _count) external onlyOwner {
    require(isReserved, "Not reserve yet");
    for (uint256 i = 0; i < _count; i++) {
      // Increase tracker and counter of ultimate assassin
      _tokenIdUltimateTrackerTeam.increment();
      _ultimateTokenCounter += 1;

      // Mint ultimate assassin
      uint256 tokenId = _tokenIdUltimateTrackerTeam.current() + 18000;
      _safeMint(_to, tokenId);
    }
  }

  /**
   * @dev Set the max mint of whitelist
   */
  function setAllowListMaxMint(uint256 maxMint) external onlyOwner {
    WHITELISTMAXMINT = maxMint;
  }

  /**
   * @dev Set Merkle Root for Phase 1 Whitelist
   */
  function setWhitelistOneMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
    whitelistOneMerkleRoot = _merkleRoot;
  }

  /**
   * @dev Get Merkle Root for Phase 1 Whitelist
   */
  function getWhitelistOneMerkleRoot() external view returns (bytes32) {
    return whitelistOneMerkleRoot;
  }

  /**
   * @dev Set Merkle Root for Phase 2 Whitelist
   */
  function setWhitelistTwoMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
    whitelistTwoMerkleRoot = _merkleRoot;
  }

  /**
   * @dev Get Merkle Root for Phase 2 Whitelist
   */
  function getWhitelistTwoMerkleRoot() external view returns (bytes32) {
    return whitelistTwoMerkleRoot;
  }

  /**
  * @dev Get the count of tokens in whitelist
  */
  function whitelistClaimedBy(address owner) external view returns (uint256){
    require(owner != address(0), 'Null address');

    return _whitelistClaimed[owner];
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseTokenURI;
  }

  function setBaseURI(string memory baseURI) public onlyOwner {
    baseTokenURI = baseURI;
  }

  /**
   * @dev Mint regular assassin with count
   */
  function mintRegularTokens(uint256 _count) external payable saleIsOpen {
    address wallet = _msgSender();
    uint256 total = _tokenIdRegularTracker.current() + REGULAR_START_AT;

    // Set limit to mint per transaction
    require(_count > 0 && _count <= 3, "Max 3 NFTs per transaction");
    // Set max limit of regular assassins
    require(total + _count <= MAX_REGULAR_TOKENS, "Max limit of Regular");
    // Check the balance
    require(msg.value >= price(_count), "Not enough ETH for transaction");

    for (uint256 i = 0; i < _count; i++) {
      // Increase tracker and counter of regular assassin
      _tokenIdRegularTracker.increment();
      _regularTokenCounter += 1;

      // Mint regular assassin
      uint256 tokenId = _tokenIdRegularTracker.current() + REGULAR_START_AT;
      _safeMint(wallet, tokenId);

      emit welcomeToAssassin(tokenId);
    }
  }

  /**
   * @dev Mint regular assassin with count for whitelist
   */
  function mintRegularTokensWhiteList(bytes32[] memory merkleProof, uint256 _count, uint256 _whitelistType) external payable nonReentrant saleIsOpenForWhitelist(merkleProof, _whitelistType) {
    address wallet = _msgSender();
    uint256 total = _tokenIdRegularTracker.current() + REGULAR_START_AT;

    // Set limit to mint per transaction
    require(_count > 0 && _count <= 3, "Max 3 NFTs per transaction");
    // Set max limit of regular assassins
    require(total + _count <= MAX_REGULAR_TOKENS, "Max limit of Regular");
    // Check the max mint of white list
    require(_whitelistClaimed[wallet] + _count <= WHITELISTMAXMINT, 'Max allowed');
    // Check the balance
    require(msg.value >= whitelistprice(_count, _whitelistType), "Not enough ETH for transaction");

    for (uint256 i = 0; i < _count; i++) {
      // Increase tracker and counter of regular assassin
      _tokenIdRegularTracker.increment();
      _regularTokenCounter += 1;
      _whitelistClaimed[wallet] += 1;

      // Mint regular assassin
      uint256 tokenId = _tokenIdRegularTracker.current() + REGULAR_START_AT;
      _safeMint(wallet, tokenId);

      emit welcomeToAssassin(tokenId);
    }
  }

  /**
   * @dev Mint super assassin using 2 regular assassins
   */
  function mintSuperTokens(uint256 _tokenIdRegular1, uint256 _tokenIdRegular2) external saleIsOpen nonReentrant saleIsOpenForSuper
  {
    address wallet = _msgSender();
    uint256 total = _tokenIdSuperTracker.current() + SUPER_START_AT - MAX_REGULAR_TOKENS;

    // Check same tokens
    require(_tokenIdRegular1 != _tokenIdRegular2, "Same tokens");
    // Set max limit of super assassins
    require(total + 1 <= MAX_SUPER_TOKENS, "Max limit of Super");
    // Check the owner of regular assassin 1
    require(ownerOf(_tokenIdRegular1) == wallet && _tokenIdRegular1 > 0 && _tokenIdRegular1 <= MAX_REGULAR_TOKENS, "Not the owner of this token");
    // Check the owner of regular assassin 2
    require(ownerOf(_tokenIdRegular2) == wallet && _tokenIdRegular2 > 0 && _tokenIdRegular2 <= MAX_REGULAR_TOKENS, "Not the owner of this token");

    // Burn 2 regular assassins and decrease the count of regular assassins
    burn(_tokenIdRegular1);
    burn(_tokenIdRegular2);
    _regularTokenCounter -= 2;

    // Increase tracker and counter of super assassin
    _tokenIdSuperTracker.increment();
    _superTokenCounter += 1;

    // Mint super assassin
    uint256 tokenIdSuper = _tokenIdSuperTracker.current() + SUPER_START_AT;
    _safeMint(wallet, tokenIdSuper);

    emit welcomeToAssassin(tokenIdSuper);
  }

  /**
   * @dev Mint ultimate assassin using 1 super assassin and 1 regular assassin
   */
  function mintUltimateTokens(uint256 _tokenIdSuper, uint256 _tokenIdRegular) external saleIsOpen saleIsOpenForUltimate
  {
    address wallet = _msgSender();
    uint256 total = _tokenIdUltimateTracker.current() + ULTIMATE_START_AT - MAX_REGULAR_TOKENS + MAX_SUPER_TOKENS;

    // Check same tokens
    require(_tokenIdSuper != _tokenIdRegular, "Same tokens");
    // Set max limit of super assassins
    require(total + 1 <= MAX_ULTIMATE_TOKENS, "Max limit of Ultimate");
    // Check the owner of super assassin
    require(ownerOf(_tokenIdSuper) == wallet && _tokenIdSuper > MAX_REGULAR_TOKENS && _tokenIdSuper <= MAX_REGULAR_TOKENS + MAX_SUPER_TOKENS, "Not the owner of this token");
    // Check the owner of regular assassin
    require(ownerOf(_tokenIdRegular) == wallet && _tokenIdRegular > 0 && _tokenIdRegular <= MAX_REGULAR_TOKENS, "Not the owner of this token");

    // Burn 1 regular assassin, 1 super assassin and decrease the count of regular and super assassin
    burn(_tokenIdSuper);
    burn(_tokenIdRegular);
    _regularTokenCounter -= 1;
    _superTokenCounter -= 1;

    // Increase tracker and counter of ultimate assassin
    _tokenIdUltimateTracker.increment();
    _ultimateTokenCounter += 1;

    // Mint ultimate assassin
    uint256 tokenIdUltimate = _tokenIdUltimateTracker.current() + ULTIMATE_START_AT;
    _safeMint(wallet, tokenIdUltimate);

    emit welcomeToAssassin(tokenIdUltimate);
  }

  function totalRegularToken() public view returns (uint256) {
    return _regularTokenCounter;
  }

  function totalSuperToken() public view returns (uint256) {
    return _superTokenCounter;
  }

  function totalUltimateToken() public view returns (uint256) {
    return _ultimateTokenCounter;
  }

  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  function setPrice(uint256 _price) external onlyOwner {
    PRICE = _price;
  }

  /**
   * @dev Set the sale active for Regular
   */
  function setRegularPause(bool _pause) external onlyOwner {
    PAUSE = _pause;
    emit PauseEvent(PAUSE);
  }

  function isRegularPaused() external view returns (bool) {
    return PAUSE;
  }

  /**
   * @dev Set the sale active for Super
   */
  function setSuperPause(bool _pause) external onlyOwner {
    SUPERMINTPAUSE = _pause;
    emit PauseEvent(SUPERMINTPAUSE);
  }

  function isSuperPaused() external view returns (bool) {
    return SUPERMINTPAUSE;
  }

  /**
   * @dev Set the sale active for Ultimate
   */
  function setUltimatePause(bool _pause) external onlyOwner {
    ULTIMATEMINTPAUSE = _pause;
    emit PauseEvent(ULTIMATEMINTPAUSE);
  }

  function isUltimatePaused() external view returns (bool) {
    return ULTIMATEMINTPAUSE;
  }

  /**
   * @dev Set the sale active for white list
   */
  function setWhitelistOnePause(bool _pause) external onlyOwner {
    WHITELISTONEPAUSE = _pause;
    emit WhitelistPauseEvent(WHITELISTONEPAUSE);
  }

  function isWhitelistOnePaused() external view returns (bool) {
    return WHITELISTONEPAUSE;
  }

  function setWhitelistTwoPause(bool _pause) external onlyOwner {
    WHITELISTTWOPAUSE = _pause;
    emit WhitelistPauseEvent(WHITELISTTWOPAUSE);
  }

  function isWhitelistTwoPaused() external view returns (bool) {
    return WHITELISTTWOPAUSE;
  }

  function price(uint256 _count) public view returns (uint256) {
    return PRICE.mul(_count);
  }

  function whitelistprice(uint256 _count, uint256 whitelistType) public pure returns (uint256) {
    if (whitelistType == 0) {
      return WHITELISTONEPRICE.mul(_count);
    }
    else {
      return WHITELISTTWOPRICE.mul(_count);
    }
  }

}
