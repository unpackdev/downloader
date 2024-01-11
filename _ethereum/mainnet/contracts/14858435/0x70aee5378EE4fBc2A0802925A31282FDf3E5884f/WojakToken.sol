// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Address.sol";
import "./Strings.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./PaymentSplitter.sol";
import "./Ownable.sol";
import "./ERC721A.sol";

import "./ProxyRegistry.sol";

contract WojakToken is ERC721A, Ownable, PaymentSplitter, ReentrancyGuard {
  using SafeMath for uint256;
  using Address for address;
  using Strings for uint256;

  uint256 public tokensRemaining = 4444;

  string public baseURI = "";
  address public proxyRegistryAddress = address(0);
  
  uint256 public mintPrice = 10000000000000000; // 0.01
  uint16 public mintTxLimit = 3;
  uint16 public mintWalletLimit = 6;
  bool public mintIsActive = false;
  mapping(address => uint16) public mintCount;

  uint16 public freeMintTxLimit = 1;
  uint16 public freeMintWalletLimit = 3;
  uint16 public freeMintAllocation = 0;
  mapping(address => uint16) public freeMintCount;

  address[] payees = [
    0x96320782a3a4762E162cB72Cde4E851c532d4141,
    0x56784c2bA9973d6544A7A790FfA7e194334e9505
  ];

  uint256[] payeeShares = [
    50,
    50 
  ];

  constructor(address _proxyRegistryAddress)
    ERC721A("Wojak", "WOJAK")
    PaymentSplitter(payees, payeeShares)
  {
    proxyRegistryAddress = _proxyRegistryAddress;
  }

  function mint(uint16 _quantity) external payable nonReentrant {
    require(mintIsActive, "mint is disabled");
    require(_quantity <= mintTxLimit && _quantity <= tokensRemaining, "invalid mint quantity");
    require(msg.value >= mintPrice.mul(_quantity), "invalid mint value");

    uint16 alreadyMinted = mintCount[msg.sender];
    require(alreadyMinted < mintWalletLimit, "reached mint wallet limit");

    _safeMint(msg.sender, _quantity);

    tokensRemaining -= _quantity;

    mintCount[msg.sender] = alreadyMinted + _quantity;
  }

  function freeMint(uint16 _quantity) external payable nonReentrant {
    require(mintIsActive, "mint is disabled");
    require(_quantity <= freeMintAllocation, "insufficient free allocation");
    require(_quantity <= freeMintTxLimit && _quantity <= tokensRemaining, "invalid mint quantity");

    uint16 alreadyFreeMinted = freeMintCount[msg.sender];
    require(alreadyFreeMinted < freeMintWalletLimit, "reached free mint wallet limit");

    _safeMint(msg.sender, _quantity);

    tokensRemaining -= _quantity;
    freeMintAllocation -= _quantity;

    freeMintCount[msg.sender] = alreadyFreeMinted + _quantity;
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), "invalid token");
        
    string memory __baseURI = _baseURI();
    return bytes(__baseURI).length > 0 ? string(abi.encodePacked(__baseURI, _tokenId.toString(), ".json")) : '.json';
  }

  function isApprovedForAll(address _owner, address _operator) override public view returns (bool) {
    if (address(proxyRegistryAddress) != address(0)) {
      ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
      if (address(proxyRegistry.proxies(_owner)) == _operator) {
        return true;
      }
    }
    return super.isApprovedForAll(_owner, _operator);
  }

  function setBaseURI(string memory _baseUri) external onlyOwner {
    baseURI = _baseUri;
  }

  function reduceTokensRemaining(uint256 _tokensRemaining) external onlyOwner {
    require(_tokensRemaining < tokensRemaining, "greater than or equal");
    tokensRemaining = _tokensRemaining;
  }

  function setMintPrice(uint256 _mintPrice) external onlyOwner {
    mintPrice = _mintPrice;
  }

  function setMintIsActive(bool _mintIsActive) external onlyOwner {
    mintIsActive = _mintIsActive;
  }

  function setMintTxLimit(uint16 _mintTxLimit) external onlyOwner {
    mintTxLimit = _mintTxLimit;
  }
  
  function setMintWalletLimit(uint16 _mintWalletLimit) external onlyOwner {
    require(_mintWalletLimit >= mintTxLimit, "invalid limit");
    mintWalletLimit = _mintWalletLimit;
  }

  function setFreeMintTxLimit(uint16 _freeMintTxLimit) external onlyOwner {
    freeMintTxLimit = _freeMintTxLimit;
  }

  function setFreeMintWalletLimit(uint16 _freeMintWalletLimit) external onlyOwner {
    require(_freeMintWalletLimit >= freeMintTxLimit, "invalid limit");
    freeMintWalletLimit = _freeMintWalletLimit;
  }

  function setFreeMintAllocation(uint16 _freeMintAllocation) external onlyOwner {
    require(_freeMintAllocation <= tokensRemaining, "exceeds total remaining");
    freeMintAllocation = _freeMintAllocation;
  }

  function setProxyRegistryAddress(address _proxyRegistryAddress) external onlyOwner {
    proxyRegistryAddress = _proxyRegistryAddress;
  }

  function airDrop(address _to, uint16 _quantity) external onlyOwner {
    require(_to != address(0), "invalid address");
    require(_quantity > 0 && _quantity <= tokensRemaining, "invalid quantity");
    _safeMint(_to, _quantity);
    tokensRemaining -= _quantity;
  }
}