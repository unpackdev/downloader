// SPDX-License-Identifier: None

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Arrays.sol";
import "./Strings.sol";
import "./ERC721AQueryable.sol";

contract Spartizens is ERC721A, ERC721AQueryable, Ownable, ReentrancyGuard {

  using Strings for uint256;

// ================== Variables Start =======================

  uint256 public extraMintPrice = 0.005 ether;
  uint256 public supplyLimit = 5573;
  uint256 public maxMintAmountPerTx = 10;

  string public uri;
  string public uriSuffix = "";
  string public hiddenMetadataUri = "soon";

  bool public sale = false;
  bool public revealed = false;

  address public immutable proxyRegistryAddress;

  mapping(address => uint256) private _freeMintedCount;

// ================== Variables End =======================  

// ================== Constructor Start =======================

  constructor(string memory _uri, address _proxyRegistryAddress) ERC721A("Spartizens", "SPRTZ") {
    setBaseURI(_uri);
    proxyRegistryAddress = _proxyRegistryAddress;
  }

// ================== Constructor End =======================

// ================== Mint Functions Start =======================

  function mint(uint256 _quantity) external payable {
    require(sale, "The Sale is paused!");

    uint256 _totalSupply = totalSupply();

    require(_quantity > 0 && _quantity <= maxMintAmountPerTx, "Exceeds Max Per Tx");
    require(_totalSupply + _quantity <= supplyLimit, "Max supply exceeded");

    // Free Mints
    uint256 payForCount = _quantity;
    uint256 freeMintCount = _freeMintedCount[msg.sender];

    if (freeMintCount < 1) {
      if (_quantity > 1) {
        payForCount = _quantity - 1;
      } else {
        payForCount = 0;
      }

      _freeMintedCount[msg.sender] = 1;
    }

    require(msg.value >= payForCount * extraMintPrice, "Insufficient Eth Sent");

    _safeMint(msg.sender, _quantity);
  }

  function Airdrop(uint256 _quantity, address _receiver) external onlyOwner {
    require(totalSupply() + _quantity <= supplyLimit, "Max supply exceeded!");
    _safeMint(_receiver, _quantity);
  }

  function reservePieces() external onlyOwner {
    require(totalSupply() == 0, "Already Reserved");

    _safeMint(msg.sender, 12);
  }

  function freeMintedCount(address owner) external view returns (uint256) {
    return _freeMintedCount[owner];
  }

// ================== Mint Functions End =======================  

// ================== Set Functions Start =======================

// reveal
  function setRevealed(bool _state) external onlyOwner {
    revealed = _state;
  }

// uri
  function setBaseURI(string memory _uri) public onlyOwner {
    uri = _uri;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

// sales toggle
  function setSaleStatus(bool _sale) external onlyOwner {
    sale = _sale;
  }

// max per tx
  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

// supply limit
  function setsupplyLimit(uint256 _supplyLimit) public onlyOwner {
    supplyLimit = _supplyLimit;
  }

// os sauce for the homies
  function isApprovedForAll(address owner, address operator)
    public
    view
    override(ERC721A, IERC721A)
    returns (bool)
  {
    OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(
      proxyRegistryAddress
    );

    if (address(proxyRegistry.proxies(owner)) == operator) {
      return true;
    }

    return super.isApprovedForAll(owner, operator);
  }

// ================== Set Functions End =======================

// ================== Withdraw Function Start =======================

  function withdraw() external onlyOwner nonReentrant {
    require(
      payable(owner()).send(address(this).balance),
      "Withdrawal Unsuccessful"
    );
  }

// ================== Withdraw Function End=======================  

// ================== Read Functions Start =======================

  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

  function tokenURI(uint256 _tokenId) public view virtual override(ERC721A, IERC721A) returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    if (revealed == false) {
      return bytes(hiddenMetadataUri).length > 0
        ? string(abi.encodePacked(hiddenMetadataUri, _tokenId.toString(), uriSuffix))
        : '';
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }

  function _baseURI() internal view override returns (string memory) {
    return uri;
  }

// ================== Read Functions End =======================  

}

contract OwnableDelegateProxy {}

contract OpenSeaProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}