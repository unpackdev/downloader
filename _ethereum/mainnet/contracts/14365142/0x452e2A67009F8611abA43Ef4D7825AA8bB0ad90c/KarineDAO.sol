//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Strings.sol";

import "./ERC721AKarine.sol";
import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./IERC2981.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";

// import "./console.sol";

contract KarineDAO is ERC721AKarine, Ownable, Pausable, ReentrancyGuard, IERC2981 {
  string private _baseTokenURI;
  mapping(address => bool) private _proxyRegistryAddress;

  uint256[5] private _mosaicDataArr; // 5*256 bit to store 1158 bit location of mosaic nft

  // init swapNFTMapping and alter value when random later
  uint8[147] private _canNotMintNFTMapping; // use for random swap nft

  uint64 private _privateOpenTime;
  uint64 private _publicOpenTime;
  uint64 private _revelationTime;

  uint16 private _startIndex = 0;
  uint16 internal _royalty = 680; // base 10000, 6.8%
  uint32 internal randNonce = 0;
  uint16 private _canMintNFTMinted;
  uint16 private _canMintNFTMintedAfterRevelation;
  uint8 private _canNotMintNFTMinted;
  bool private _revelated = false;

  address payable private _productOwnerAddr;

  // constant
  uint256 public constant VERSION = 10200;
  uint16 public constant BASE = 10000; // base for royalty

  uint8 public immutable MAX_MINT_TIER_1 = 3;
  uint8 public immutable MAX_MINT_TIER_2 = 1;
  uint8 public immutable MAX_MINT_PUBLIC = 10;

  /// @dev NFT JSON ID map : | 210 premint | 1158 can mint | 147 swap only |
  /// @dev NFT ID map : | 210 premint | <= 1158 can mint | 147 swap only ~ can mint left |
  uint16 public immutable TOTAL_PREMINT_NFT;
  uint16 public immutable TOTAL_CAN_MINT_NFT;
  uint16 public immutable TOTAL_CANNOT_MINT_NFT;

  uint256 public immutable PRIVATE_PRICE;
  uint256 public immutable PUBLIC_PRICE;

  constructor(
    string memory baseURI,
    address payable productOwnerAddr,
    uint256[5] memory mosaicDataArr,
    uint64 privateOpenTime,
    uint64 publicOpenTime,
    uint64 revelationTime,
    uint16 totalPremintNFT,
    uint16 totalCanmintNFT,
    uint16 totalCannotmintNFT,
    uint256 privatePrice,
    uint256 publicPrice
  ) ERC721AKarine("KRDAOT", "KRDAOT") {
    _baseTokenURI = baseURI;
    _productOwnerAddr = productOwnerAddr;
    _mosaicDataArr = mosaicDataArr;
    _privateOpenTime = privateOpenTime;
    _publicOpenTime = publicOpenTime;
    _revelationTime = revelationTime;

    // init immutable
    TOTAL_PREMINT_NFT = totalPremintNFT;
    TOTAL_CAN_MINT_NFT = totalCanmintNFT;
    TOTAL_CANNOT_MINT_NFT = totalCannotmintNFT;

    PRIVATE_PRICE = privatePrice;
    PUBLIC_PRICE = publicPrice;

    // init swapNFTMapping and alter value when random later
    for (uint8 i = 0; i < totalCannotmintNFT; i++) {
      _canNotMintNFTMapping[i] = i;
    }
    _safeMint(_productOwnerAddr, totalPremintNFT);
  }

  ///@dev productOwner addr

  function setProductOwner(address addr) external onlyOwner {
    _productOwnerAddr = payable(addr);
  }

  function getProductOwner() external view returns (address) {
    return _productOwnerAddr;
  }

  ///@dev allow set _mosaicDataArr before _revelated to avoid issue
  function setMosaicDataArr(uint256[5] memory mosaicDataArr) external onlyOwner {
    require(!_revelated);
    _mosaicDataArr = mosaicDataArr;
  }

  ///@dev setTime

  function setTime(
    uint64 privateOpenTime,
    uint64 publicOpenTime,
    uint64 revelationTime
  ) external onlyOwner {
    require(!_revelated);
    _privateOpenTime = privateOpenTime;
    _publicOpenTime = publicOpenTime;
    _revelationTime = revelationTime;
  }

  /**
  @dev royalty
   */

  function royaltyInfo(uint256, uint256 _salePrice)
    external
    view
    override
    returns (address receiver, uint256 royaltyAmount)
  {
    return (_productOwnerAddr, (_salePrice * _royalty) / BASE);
  }

  function setRoyalty(uint16 royalty) external onlyOwner {
    _royalty = royalty;
  }

  ///@dev white list

  function addToWhiteList1(address[] memory addrArr) external {
    require((msg.sender == _productOwnerAddr) || (msg.sender == owner()));
    for (uint256 i = 0; i < addrArr.length; i++) {
      _addressData[addrArr[i]].limitPrivateMint = MAX_MINT_TIER_1;
    }
  }

  function addToWhiteList2(address[] memory addrArr) external {
    require((msg.sender == _productOwnerAddr) || (msg.sender == owner()));
    for (uint256 i = 0; i < addrArr.length; i++) {
      _addressData[addrArr[i]].limitPrivateMint = MAX_MINT_TIER_2;
    }
  }

  function removeFromWhiteList(address[] memory addrArr) external {
    require((msg.sender == _productOwnerAddr) || (msg.sender == owner()));
    for (uint256 i = 0; i < addrArr.length; i++) {
      _addressData[addrArr[i]].limitPrivateMint = 0;
    }
  }

  function getPrivateLimitOfAddr(address addr) external view returns (uint8) {
    return _addressData[addr].limitPrivateMint;
  }

  ///@dev cannot underflow if everything correct
  function getMintTimesLeft(address addr, bool isPrivate) external view returns (uint256) {
    if (!_revelated) {
      if (isPrivate) {
        if (_addressData[addr].limitPrivateMint > _addressData[addr].numberPrivateMinted) {
          return _addressData[addr].limitPrivateMint - _addressData[addr].numberPrivateMinted;
        } else {
          return 0;
        }
      } else {
        return MAX_MINT_PUBLIC - (_numberMinted(addr) - _addressData[addr].numberPrivateMinted);
      }
    } else {
      if (addr == _productOwnerAddr) {
        return TOTAL_CAN_MINT_NFT - (_canMintNFTMinted + _canMintNFTMintedAfterRevelation);
      } else {
        return 0;
      }
    }
  }

  // check mosaic nft

  function isMosaic(uint16 tokenId) public view returns (bool) {
    if (!_revelated || tokenId < TOTAL_PREMINT_NFT) {
      return false;
    }
    uint16 indexInCanMintNFT = tokenIdToIndex(tokenId) - TOTAL_PREMINT_NFT;
    uint16 idxInMosaicDataArr = indexInCanMintNFT / 256;
    if (idxInMosaicDataArr >= _mosaicDataArr.length) {
      return false;
    }
    // get bit info
    uint256 bitValue = (_mosaicDataArr[idxInMosaicDataArr] & (1 << (indexInCanMintNFT % 256)));
    return bitValue > 0;
  }

  /// @dev minting

  /**
   * @dev mints `numToken` tokens and assigns it to
   * `msg.sender` by calling _safeMint function.
   *
   * Requirements:
   * - Current timestamp must within period of private sale `_privateOpenTime` - `_publicOpenTime`.
   * - Ether amount sent greater or equal the `PRIVATE_PRICE` multipled by `numToken`.
   * - `numToken` within limits of max number of tokens minted in single txn.
   * @param numToken - Number of tokens to be minted
   */
  function mintPrivateSale(uint8 numToken) external payable whenNotPaused {
    uint256 time = block.timestamp;
    require(
      (!_revelated) &&
        (time >= _privateOpenTime && time < _publicOpenTime) &&
        _addressData[msg.sender].limitPrivateMint > 0,
      "Mint is not open"
    );
    require((_canMintNFTMinted + numToken) <= TOTAL_CAN_MINT_NFT, "Out of stock");
    require(!Address.isContract(msg.sender));
    require(numToken > 0, "Empty numToken");
    require(msg.value >= PRIVATE_PRICE * numToken, "Insufficient ETH");
    require(
      (_addressData[msg.sender].numberPrivateMinted + numToken) <= _addressData[msg.sender].limitPrivateMint,
      "Out of times"
    );
    _addressData[msg.sender].numberPrivateMinted += numToken;
    _canMintNFTMinted += numToken;

    _safeMint(msg.sender, numToken);
  }

  /**
   * @dev mints `numToken` tokens and assigns it to
   * `msg.sender` by calling _safeMint function.
   *
   * Requirements:
   * - Current timestamp must within period of public sale `_publicOpenTime` - `_revelationTime`.
   * - Ether amount sent greater or equal the `PUBLIC_PRICE` multipled by `numToken`.
   * - `numToken` within limits of max number of tokens minted in single txn.
   * @param numToken - Number of tokens to be minted
   */
  function mintPublicSale(uint8 numToken) external payable whenNotPaused {
    uint256 time = block.timestamp;
    require((!_revelated) && (time >= _publicOpenTime && time < _revelationTime), "Mint is not open");
    require((_canMintNFTMinted + numToken) <= TOTAL_CAN_MINT_NFT, "Out of stock");
    require(!Address.isContract(msg.sender));
    require(numToken > 0, "Empty numToken");
    require(msg.value >= PUBLIC_PRICE * numToken, "Insufficient ETH");

    require(
      (_numberMinted(msg.sender) - _addressData[msg.sender].numberPrivateMinted) + numToken <= MAX_MINT_PUBLIC,
      "Out of times"
    );

    _canMintNFTMinted += numToken;

    _safeMint(msg.sender, numToken);
  }

  function mintAndTransferAfterRevelation(uint8 numToken, address addr) external whenNotPaused {
    require(_revelated && msg.sender == _productOwnerAddr);
    require((_canMintNFTMinted + _canMintNFTMintedAfterRevelation + numToken) <= TOTAL_CAN_MINT_NFT, "Out of NFT");
    uint256 startTokenId = _currentIndex;
    for (uint8 i = 0; i < numToken; i++) {
      _ownerships[startTokenId].isCanMintNFT = true;
      _ownerships[startTokenId].mappingIndex = _canMintNFTMinted + _canMintNFTMintedAfterRevelation + i;

      startTokenId++;
    }

    _canMintNFTMintedAfterRevelation += numToken;
    _safeMint(addr, numToken);
  }

  /**
   @dev revelation
   */
  function revelate(string memory baseTokenURI, bool mintAllUnMinted) external onlyOwner {
    require(block.timestamp >= _revelationTime);
    if (mintAllUnMinted) {
      _safeMint(_productOwnerAddr, TOTAL_CAN_MINT_NFT - _canMintNFTMinted);
      _canMintNFTMinted = TOTAL_CAN_MINT_NFT;
    }
    // random _startIndex
    _startIndex = uint16(random(TOTAL_CAN_MINT_NFT));
    _baseTokenURI = baseTokenURI;
    _revelated = true;
  }

  function emergencyUnrevelate() external onlyOwner {
    _revelated = false;
  }

  /**
   @dev swap
   */

  function random(uint256 _modulus) private returns (uint256) {
    randNonce++;
    return uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce))) % _modulus;
  }

  function swap(uint16[] memory tokenIds) external whenNotPaused {
    require(block.timestamp >= _revelationTime && _revelated, "Swap is not open");
    require((tokenIds.length % 2) == 0, "Length must be even");
    uint8 numToken = uint8(tokenIds.length / 2);
    require((_canNotMintNFTMinted + numToken) <= TOTAL_CANNOT_MINT_NFT, "Out of NFT");

    for (uint16 i = 0; i < tokenIds.length; i++) {
      require(isMosaic(tokenIds[i]), "Only use mosaic");
    }
    // transfer all mosaic to product owner address
    for (uint16 i = 0; i < tokenIds.length; i++) {
      transferFrom(msg.sender, _productOwnerAddr, tokenIds[i]);
    }

    // random NFT

    uint256 startTokenId = _currentIndex;
    uint8 updatedCanNotMintNFTMinted = _canNotMintNFTMinted;
    for (uint8 i = 0; i < numToken; i++) {
      uint8 randomNumber = updatedCanNotMintNFTMinted +
        uint8(random(TOTAL_CANNOT_MINT_NFT - updatedCanNotMintNFTMinted));
      // swap value in _canNotMintNFTMapping
      uint8 temp = _canNotMintNFTMapping[randomNumber];
      _canNotMintNFTMapping[randomNumber] = _canNotMintNFTMapping[updatedCanNotMintNFTMinted];
      _canNotMintNFTMapping[updatedCanNotMintNFTMinted] = temp;

      _ownerships[startTokenId].isCanMintNFT = false;
      _ownerships[startTokenId].mappingIndex = temp;

      startTokenId++;
      updatedCanNotMintNFTMinted++;
    }
    _canNotMintNFTMinted = updatedCanNotMintNFTMinted;
    // mint NFT to msg.sender
    _safeMint(msg.sender, numToken);
  }

  /**
   @dev tokenUri
   */
  function _baseURI() internal view override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string memory baseURI) external onlyOwner {
    require(!_revelated);
    _baseTokenURI = baseURI;
  }

  function tokenIdToIndex(uint256 tokenId) public view returns (uint16) {
    if (!_revelated) {
      return uint16(tokenId);
    }
    uint256 index;
    if (tokenId < TOTAL_PREMINT_NFT) {
      // for premint NFT mint in correct time
      index = tokenId + _startIndex;
      index %= TOTAL_PREMINT_NFT;
    } else if (tokenId < (TOTAL_PREMINT_NFT + _canMintNFTMinted)) {
      // for canmint NFT mint in correct time
      index = (tokenId - TOTAL_PREMINT_NFT) + _startIndex;
      index %= TOTAL_CAN_MINT_NFT;
      index += TOTAL_PREMINT_NFT;
    } else if (_ownerships[tokenId].isCanMintNFT) {
      // for canmint NFT mint after revelation
      index = _ownerships[tokenId].mappingIndex + _startIndex;
      index %= TOTAL_CAN_MINT_NFT;
      index += TOTAL_PREMINT_NFT;
    } else {
      // for can not mint nft
      index = _ownerships[tokenId].mappingIndex + TOTAL_PREMINT_NFT + TOTAL_CAN_MINT_NFT;
    }
    return uint16(index);
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

    string memory baseURI = _baseURI();
    uint256 index = tokenIdToIndex(tokenId);

    return
      bytes(baseURI).length != 0
        ? string(abi.encodePacked(baseURI, Strings.toString(index), ".json"))
        : string(abi.encodePacked(Strings.toString(index), ".json"));
  }

  /**
   @dev withdraw
   */
  function withdraw() external nonReentrant whenNotPaused {
    require(msg.sender == _productOwnerAddr);
    payable(msg.sender).transfer(address(this).balance);
  }

  /** @dev pause */

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  /**
  @dev get tokenId to nft mapping
   */

  function getAllTokenIdToIndex() external view returns (uint16[] memory) {
    uint16[] memory allTokenIdToIndex = new uint16[](_currentIndex);
    for (uint256 i; i < _currentIndex; i++) {
      allTokenIdToIndex[i] = uint16(tokenIdToIndex(i));
    }
    return allTokenIdToIndex;
  }

  function getPrivateOpenTime() external view returns (uint64) {
    return _privateOpenTime;
  }

  function getPublicOpenTime() external view returns (uint64) {
    return _publicOpenTime;
  }

  function getRevelationTime() external view returns (uint64) {
    return _revelationTime;
  }

  function getStartIndex() external view returns (uint16) {
    return _startIndex;
  }

  function getCanMintNFTMinted() external view returns (uint16) {
    return _canMintNFTMinted + _canMintNFTMintedAfterRevelation;
  }

  function getCanNotMintNFTMinted() external view returns (uint16) {
    return _canNotMintNFTMinted;
  }

  function getMosaicDataArr() external view returns (uint256[5] memory) {
    return _mosaicDataArr;
  }

  function getRevelated() external view returns (bool) {
    return _revelated;
  }

  /**
   * Override isApprovedForAll to whitelisted marketplaces to enable gas-free listings.
   *
   */
  function isApprovedForAll(address owner, address operator) public view override returns (bool) {
    // check if this is an approved marketplace
    if (_proxyRegistryAddress[operator]) {
      return true;
    }
    // otherwise, use the default ERC721 isApprovedForAll()
    return super.isApprovedForAll(owner, operator);
  }

  /*
   * Function to set status of proxy contracts addresses
   *
   */
  function setProxy(address proxyAddress, bool value) external onlyOwner {
    _proxyRegistryAddress[proxyAddress] = value;
  }
}
