// SPDX-License-Identifier: MIT
/*
███╗  ██╗ █████╗ ███╗   ███╗███████╗██╗     ███████╗ ██████╗ ██████╗  ███████╗ █████╗ ██╗     ██╗  ██╗ ██████╗
████╗ ██║██╔══██╗████╗ ████║██╔════╝██║     ██╔════╝██╔════╝██╔════╝  ██╔════╝██╔══██╗██║     ██║ ██╔╝██╔════╝
██╔██╗██║███████║██╔████╔██║█████╗  ██║     █████╗ ╚█████╗ ╚█████╗    █████╗  ██║  ██║██║     █████═╝ ╚█████╗
██║╚████║██╔══██║██║╚██╔╝██║██╔══╝  ██║     ██╔══╝  ╚═══██╗ ╚═══██╗   ██╔══╝  ██║  ██║██║     ██╔═██╗  ╚═══██╗
██║ ╚███║██║  ██║██║ ╚═╝ ██║███████╗███████╗███████╗██████╔╝██████╔╝  ██║      █████╔╝███████╗██║ ╚██╗██████╔╝
╚═╝  ╚══╝╚═╝  ╚═╝╚═╝     ╚═╝╚══════╝╚══════╝╚══════╝╚═════╝ ╚═════╝   ╚═╝      ╚════╝ ╚══════╝╚═╝  ╚═╝╚═════╝
*/

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./SafeMath.sol";
import "./Strings.sol";
import "./Ownable.sol";

/// @title Contract for NamelessFolks
/// @author AL GORITHM
contract Namelessfolks is ERC721Enumerable, Ownable {

  using SafeMath for uint256;

  uint256 public constant FOLK_GIVEAWAY = 498;
  uint256 public constant FOLK_PRIVATE = 2;
  uint256 public constant FOLK_PUBLIC = 4000;
  uint256 public constant FOLK_MAX = FOLK_GIVEAWAY + FOLK_PRIVATE + FOLK_PUBLIC;

  uint256 FOLK_PRICE = 0.02 ether;

  uint256 public constant EFS_FOLK_MAX_PER_MINT = 5;
  uint256 public constant VW_FOLK_MAX_PER_MINT = 2;
  uint256 public constant FOLK_MAX_PER_MINT = 5;

  bool private _isOnPresale = false;
  bool private _isOnPublicSale = false;
  uint256 private giveAwayMinted;
  uint256 private publicMinted;
  uint256 private privateMinted;
  string private _baseTokenURI;

  address a1 = 0x49Bc197d48d21C56615211ad067f01A461F355fA;
  address a2 = 0xdab0663ae4d3d69d96Dc8314adBAea74552d25B5;

  mapping(address => bool) public earlyFolkSupporters;
  uint256 public earlyFolkSupportersPurchaseLimit = 5;

  mapping(address => bool) public verifiedWhiteList;
  uint256 public verifiedWhiteListPurchaseLimit = 2;


  mapping(address => uint256) public presalePurchases;

  mapping(uint256 => address) public folkToOwner;

  constructor(string memory baseURI) ERC721("Nameless Folks", "FOLK") {
      setBaseURI(baseURI);
  }

  function earlyFolkSupportersMint(uint256 quantity) external payable {
    require(_isOnPresale, "TRANSACTION: Presale is no longer active");
    require(!_isOnPublicSale, "TRANSACTION: Public sale is active");
    require(earlyFolkSupporters[msg.sender], "TRANSACTION: Not in Early Folk Supporters List");
    require(FOLK_MAX > totalSupply(), "SUPPLY: Nameless Folks Token cap reached");
    require(quantity <= EFS_FOLK_MAX_PER_MINT, "TRANSACTION: Exceed Max per mint");
    require(msg.value >= FOLK_PRICE * quantity, "PAYMENT: Insufficient ETH value");
    require(publicMinted + quantity <= FOLK_PUBLIC, "SUPPLY: Nameless Folks Presale Sold Out");
    require(presalePurchases[msg.sender] + quantity <= earlyFolkSupportersPurchaseLimit, "TRANSACTION: Exceeded Max Early Folk Supporter Allocation");

    for (uint256 i = 0; i < quantity; i++) {
        publicMinted++;
        presalePurchases[msg.sender]++;
        uint256 supply = totalSupply()+1;
        _safeMint(msg.sender, supply);
        folkToOwner[supply] = msg.sender;
    }
  }

  function addToEarlyFolkSupporters(address[] calldata entries) external onlyOwner {
      for(uint256 i = 0; i < entries.length; i++) {
          address entry = entries[i];
          require(entry != address(0), "EFS WHITELIST: Null Address");
          require(!earlyFolkSupporters[entry], "EFS WHITELIST: Duplicate Entry");
          earlyFolkSupporters[entry] = true;
      }
  }

  function removeFromEarlyFolkSupporters(address[] calldata entries) external onlyOwner {
      for(uint256 i = 0; i < entries.length; i++) {
          address entry = entries[i];
          require(entry != address(0), "EFS WHITELIST: Null Address");
          earlyFolkSupporters[entry] = false;
      }
  }

  function verifiedWhiteListMint(uint256 quantity) external payable {
    require(_isOnPresale, "TRANSACTION: Presale is no longer active");
    require(!_isOnPublicSale, "TRANSACTION: Public sale is active");
    require(verifiedWhiteList[msg.sender], "TRANSACTION: Not in Verified WhiteList");
    require(FOLK_MAX > totalSupply(), "SUPPLY: Nameless Folks Token cap reached");
    require(quantity <= VW_FOLK_MAX_PER_MINT, "TRANSACTION: Exceed Max per mint");
    require(msg.value >= FOLK_PRICE * quantity, "PAYMENT: Insufficient ETH value");
    require(publicMinted + quantity <= FOLK_PUBLIC, "SUPPLY: Nameless Folks Presale Sold Out");
    require(presalePurchases[msg.sender] + quantity <= verifiedWhiteListPurchaseLimit, "TRANSACTION: Exceeded Max Verified Whitelist Member Allocation");

    for (uint256 i = 0; i < quantity; i++) {
        publicMinted++;
        presalePurchases[msg.sender]++;
        uint256 supply = totalSupply()+1;
        _safeMint(msg.sender, supply);
        folkToOwner[supply] = msg.sender;
    }
  }

  function addToVerifiedWhiteList(address[] calldata entries) external onlyOwner {
      for(uint256 i = 0; i < entries.length; i++) {
          address entry = entries[i];
          require(entry != address(0), "VW WHITELIST: Null Address");
          require(!verifiedWhiteList[entry], "VW WHITELIST: Duplicate Entry");
          verifiedWhiteList[entry] = true;
      }
  }

  function removeFromVerifiedWhiteList(address[] calldata entries) external onlyOwner {
      for(uint256 i = 0; i < entries.length; i++) {
          address entry = entries[i];
          require(entry != address(0), "VW WHITELIST: Null Address");
          verifiedWhiteList[entry] = false;
      }
  }

  function giveAwayMint(address[] calldata receivers) external onlyOwner {
      require(totalSupply() + receivers.length <= FOLK_MAX, "SUPPLY: Nameless Folks Token cap reached");
      require(giveAwayMinted + receivers.length <= FOLK_GIVEAWAY, "SUPPLY: Give away supply empty");

      for (uint256 i = 0; i < receivers.length; i++) {
          giveAwayMinted++;
          uint256 supply = totalSupply()+1;
          _safeMint(receivers[i], supply);
          folkToOwner[supply] = receivers[i];
      }
  }

  function publicSaleMint(uint256 quantity) external payable {
    require(!_isOnPresale, "TRANSACTION: Presale is active");
    require(_isOnPublicSale, "TRANSACTION: Public sale is not active");
    require(FOLK_MAX > totalSupply(), "SUPPLY: Nameless Folks Token cap reached");
    require(msg.value >= FOLK_PRICE * quantity, "PAYMENT: Insufficient ETH value");
    require(publicMinted <= FOLK_PUBLIC, "SUPPLY: Nameless Folks Sold Out");
    require(quantity <= FOLK_MAX_PER_MINT, "TRANSACTION: Exceed Max per mint");
    require(publicMinted + quantity <= FOLK_PUBLIC, "SUPPLY: Exceed Nameless Folks Public Max");

    for (uint256 i = 0; i < quantity; i++) {
        publicMinted++;
        uint256 supply = totalSupply()+1;
        _safeMint(msg.sender, supply);
        folkToOwner[supply] = msg.sender;
    }
  }

  function privateMint(address _to, uint256 _tokenId) public onlyOwner returns (uint256) {
    require(!_isOnPresale, "TRANSACTION:  Presale is active");
    require(!_isOnPublicSale, "TRANSACTION:  Public sale is active");
    require(FOLK_MAX > totalSupply(), "SUPPLY:  Nameless Folks Token cap reached");
    require(privateMinted <= FOLK_PRIVATE, "SUPPLY:  Nameless Folks Sold Out");

    privateMinted++;
    totalSupply() + 1;
    _safeMint(_to, _tokenId);

    folkToOwner[_tokenId] = _to;
    return _tokenId;
  }

  function getFolksByOwner(address _owner) external view returns (uint256[] memory) {
    uint256 owned = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](owned);
    for(uint256 i = 0; i < owned; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }

  function numberOfFolksOwned(address _owner) external view returns (uint256) {
    return balanceOf(_owner);
  }

  function isOnEarlyFolkSupporters(address addr) external view returns (bool) {
      return earlyFolkSupporters[addr];
  }

  function isOnVerifiedWhiteList(address addr) external view returns (bool) {
      return verifiedWhiteList[addr];
  }

  function folkOwner(uint256 _tokenId) external view returns (address) {
    return folkToOwner[_tokenId];
  }

  function setFOLKPrice(uint256 _price) external onlyOwner {
    FOLK_PRICE = _price;
  }

  function getFOLKPrice() external view returns (uint256) {
    return FOLK_PRICE;
  }

  function isOnPreSale() external view returns (bool) {
    return _isOnPresale;
  }

  function switchPresale(bool val) public onlyOwner {
      _isOnPresale = val;
  }

  function isOnPublicSale() external view returns (bool) {
    return _isOnPublicSale;
  }

  function switchPublicSale(bool val) public onlyOwner {
      _isOnPublicSale = val;
  }

  function totalGiveAwayMinted() external view returns (uint256) {
    return giveAwayMinted;
  }

  function totalPublicMinted() external view returns (uint256) {
    return publicMinted;
  }

  function totalPrivateMinted() external view returns (uint256) {
    return privateMinted;
  }

  function presalePurchasedCount(address addr) external view returns (uint256) {
      return presalePurchases[addr];
  }

  function setMembersAddresses(address[] memory _a) public onlyOwner {
      a1 = _a[0];
      a2 = _a[1];
  }

  function getMembersAddresses() public onlyOwner view returns (address[] memory) {
      address[] memory ownerAddresses = new address[](2);
      ownerAddresses[0] = a1;
      ownerAddresses[1] = a2;
      return ownerAddresses;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
      require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
      string memory baseURI = _baseURI();
      return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
  }

  function _baseURI() internal view virtual override returns (string memory) {
      return _baseTokenURI;
  }

  function setBaseURI(string memory baseURI) public onlyOwner {
      _baseTokenURI = baseURI;
  }

  function withdrawTeam(uint256 amount) external onlyOwner {
      uint256 _each = amount / 2;
      require(payable(a1).send(_each));
      require(payable(a2).send(_each));
  }

}
