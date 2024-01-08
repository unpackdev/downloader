//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity ^0.8.6;

import "./Ownable.sol";
import "./BadCacheI.sol";
import "./ERC721URIStorage.sol";

contract RestoredCache is ERC721URIStorage, Ownable {
  address private badCache721 = 0x3879cc5C624a7b101b2Bf1b1a2cEea74f6ECa53D;
  bool private paused = true;
  uint256 private balance = 0;
  string private baseURI;
  address private bank = 0xBd40aDD28615FEbF5BdA18afea24C7908695210b;
  uint256[] private mintedTokens;

  mapping(uint8 => uint256) private amountPerType;
  event MintedRestoredCache(address indexed _sender, uint256 indexed _tokenId);
  event Witdraw(address indexed _receiver, uint256 indexed _amount);

  constructor() onlyOwner ERC721("RestoredCache", "RestoredCache") {
    amountPerType[0] = 300000000000000000;
    amountPerType[1] = 100000000000000000;
    amountPerType[2] = 100000000000000000;
    amountPerType[3] = 100000000000000000;
    amountPerType[4] = 100000000000000000;
    amountPerType[5] = 100000000000000000;
    amountPerType[6] = 100000000000000000;
    amountPerType[7] = 100000000000000000;
    amountPerType[8] = 100000000000000000;
    amountPerType[9] = 100000000000000000;
    amountPerType[10] = 100000000000000000;
  }

  function exists(uint256 _tokenId) public view returns (bool) {
    return _exists(_tokenId);
  }

  /**
   * @dev Purchase a RestoredCache based by a holder of a BadCache721. Also the _badCache721Id must be a BadCache721 token that has the sender as the owner
   *
   * Requirements:
   *
   * - `_type` - defines a type of metadata type (video or image) and must exists in allowed types.
   *             Also the amount of ETH sent must be equal with the amount of ETH required for this type
   */
  function purchase(uint256 _tokenId, uint8 _type) public payable tokenExists(_tokenId) {
    require(_tokenId > 0, "Token Id can not be zero");
    require(amountPerType[_type] > 0, "Type of metadata not found");
    require(amountPerType[_type] == msg.value, "Amount of ETH <> Meta type");

    mintedTokens.push(_tokenId);

    (bool succeed, ) = bank.call{ value: msg.value }("");
    require(succeed, "Purchase not succeeded");

    mintRestoredCache(msg.sender, _tokenId, _type);
  }

  /**
   * @dev Minting a RestoredCache by a BadCache721 Holder
   *
   * Requirements:
   * - `_sender` - to not be the zero address`
   * - `_sender` - to be the owner of _badCache721Id on BadCache721
   *
   */
  function mintRestoredCache(
    address _sender,
    uint256 _tokenId,
    uint8 _type
  ) private {
    require(_sender != address(0), "Can not mint to address 0");
    uint256 tokenIdToBe = _tokenId * 1000 + _type;
    require(!this.exists(tokenIdToBe), "Token already exists");

    bool validPurchase = !paused;

    //if paused == true, means only BadCache 721 holders can mint
    if (paused) {
      require(
        BadCacheI(badCache721).balanceOf(_sender) > 0 &&
          BadCacheI(badCache721).exists(_tokenId) &&
          BadCacheI(badCache721).ownerOf(_tokenId) == _sender,
        "Sender has problems with BadCache721"
      );

      validPurchase = true;
    }
    if (validPurchase) _mint721(tokenIdToBe, _sender);
  }

  /**
   * @dev minting RestoredCache function and transfer to the owner
   */
  function _mint721(uint256 _tokenId, address _owner) private {
    _safeMint(_owner, _tokenId);
    _setTokenURI(_tokenId, tokenURI(_tokenId));
    emit MintedRestoredCache(_owner, _tokenId);
  }

  /**
   * @dev sets proxied token for BadCache721.
   * Requirements:
   *
   * - `_token` must not be address zero
   */
  function setBadCache721ProxiedAddress(address _token) public onlyOwner {
    require(_token != address(0), "Can't set to the address 0");
    badCache721 = _token;
  }

  /**
   * @dev get BadCache721 proxied token
   */
  function getBadCache721ProxiedAddress() public view returns (address) {
    return badCache721;
  }

  /**
   * @dev set Bank address
   */
  function setBank(address _bank) public onlyOwner {
    bank = _bank;
  }

  /**
   * @dev get Bank address
   */
  function getBank() public view returns (address) {
    return bank;
  }

  /**
   * @dev sets paused
   */
  function setPaused(bool _paused) public onlyOwner {
    paused = _paused;
  }

  /**
   * @dev gets paused
   */
  function getPaused() public view returns (bool) {
    return paused;
  }

  /**
   * @dev gets base token uri
   */
  function baseTokenURI() internal view returns (string memory) {
    return baseURI;
  }

  /**
   * @dev owner can change base token uri
   */
  function changeBaseTokenURI(string memory _uri) public onlyOwner {
    baseURI = _uri;
  }

  /**
   * @dev appends 2 strings
   */
  function append(string memory a, string memory b) internal pure returns (string memory) {
    return string(abi.encodePacked(a, b, ".json"));
  }

  /**
   * @dev returns full token uri based on _tokenId and _type
   */
  function tokenURIWithType(uint8 _type, uint256 _tokenId) public view returns (string memory) {
    return append(baseTokenURI(), Strings.toString(_tokenId * 1000 + _type));
  }

  /**
   * @dev returns full token uri based on _tokenId
   */
  function tokenURI(uint256 _tokenId) public view override returns (string memory) {
    return append(baseTokenURI(), Strings.toString(_tokenId));
  }

  /**
   * @dev returns minted tokens ids
   */
  function getMintedTokens() public view returns (uint256[] memory) {
    return mintedTokens;
  }

  /**
   * @dev checks if a token was already minted with the same tokenId, a final tokenId will be a composition of tokenId * 1000 + tokenType
   * that is why we need to verify the purchase against tokenId
   */
  modifier tokenExists(uint256 _tokenId) {
    for (uint256 i; i < mintedTokens.length; i++) {
      if (mintedTokens[i] == _tokenId) require(false, "Token minted already");
    }
    _;
  }
}
