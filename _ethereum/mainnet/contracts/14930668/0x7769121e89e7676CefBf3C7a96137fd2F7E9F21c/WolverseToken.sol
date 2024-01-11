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

contract WolverseToken is ERC721A, Ownable, PaymentSplitter, ReentrancyGuard {
  using SafeMath for uint256;
  using Address for address;
  using Strings for uint256;

  uint16 public maxSupply = 2222;

  string public baseURI = "";
  address public proxyRegistryAddress = address(0);
  address public burnContractAddress = address(0);

  bool public paidMintIsActive = false;
  uint256 public paidMintPrice = 10000000000000000;
  uint16 public paidMintTxLimit = 5;

  bool public freeMintIsActive = false;
  uint16 public freeMintWalletLimit = 1;
  uint16 public freeMintAllocation = 0;
  mapping(address => uint16) public freeMintCount;

  address[] payees = [
    0x8F22A0a7dC17Aef7f712908B66507132FB847c32
  ];

  uint256[] payeeShares = [
    100
  ];

  constructor(address _proxyRegistryAddress)
    ERC721A("WolVerse", "WOLVERSE")
    PaymentSplitter(payees, payeeShares)
  {
    proxyRegistryAddress = _proxyRegistryAddress;
  }

  function tokensRemaining() public view returns (uint256) {
    return uint256(maxSupply).sub(totalSupply());
  }

  function tokensOfOwner(address _owner) external view returns (uint256[] memory) {
    uint256 tokenIdsIdx;
    address currOwnershipAddr;
    uint256 tokenIdsLength = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](tokenIdsLength);
    TokenOwnership memory ownership;

    for (uint256 i = _startTokenId(); tokenIdsIdx != tokenIdsLength; i++) {
      ownership = _ownerships[i];
      if (ownership.burned) {
        continue;
      }
      if (ownership.addr != address(0)) {
        currOwnershipAddr = ownership.addr;
      }
      if (currOwnershipAddr == _owner) {
        tokenIds[tokenIdsIdx++] = i;
      }
    }
    return tokenIds;
  }

  function paidMint(uint16 _quantity) external payable nonReentrant {
    require(paidMintIsActive, "mint is disabled");
    require(_quantity <= paidMintTxLimit && _quantity <= tokensRemaining(), "invalid mint quantity");
    require(msg.value >= paidMintPrice.mul(_quantity), "invalid mint value");

    _safeMint(msg.sender, _quantity);
  }

  function freeMint(uint16 _quantity) external payable nonReentrant {
    require(freeMintIsActive, "mint is disabled");
    require(_quantity <= freeMintAllocation, "insufficient free allocation");
    require(_quantity <= tokensRemaining(), "invalid mint quantity");

    uint16 alreadyFreeMinted = freeMintCount[msg.sender];
    require((alreadyFreeMinted + _quantity) <= freeMintWalletLimit, "exceeds free mint wallet limit");

    _safeMint(msg.sender, _quantity);

    freeMintCount[msg.sender] = alreadyFreeMinted + _quantity;
    freeMintAllocation -= _quantity;
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

  function reduceMaxSupply(uint16 _maxSupply) external onlyOwner {
    require(_maxSupply < maxSupply, "must be less than curernt max supply");
    require(_maxSupply >= totalSupply(), "must be gte the total supply");
    require(_maxSupply >= freeMintAllocation, "must be gte free mint allocation");
    maxSupply = _maxSupply;
  }

  function setPaidMintIsActive(bool _paidMintIsActive) external onlyOwner {
    paidMintIsActive = _paidMintIsActive;
  }

  function setPaidMintPrice(uint256 _paidMintPrice) external onlyOwner {
    paidMintPrice = _paidMintPrice;
  }

  function setPaidMintTxLimit(uint16 _paidMintTxLimit) external onlyOwner {
    paidMintTxLimit = _paidMintTxLimit;
  }

  function setFreeMintWalletLimit(uint16 _freeMintWalletLimit) external onlyOwner {
    freeMintWalletLimit = _freeMintWalletLimit;
  }

  function setFreeMintIsActive(bool _freeMintIsActive) external onlyOwner {
    freeMintIsActive = _freeMintIsActive;
  }

  function setFreeMintAllocation(uint16 _freeMintAllocation) external onlyOwner {
    require(_freeMintAllocation <= tokensRemaining(), "exceeds total remaining");
    freeMintAllocation = _freeMintAllocation;
  }

  function setProxyRegistryAddress(address _proxyRegistryAddress) external onlyOwner {
    proxyRegistryAddress = _proxyRegistryAddress;
  }

  function airDrop(address _to, uint16 _quantity) external onlyOwner {
    require(_to != address(0), "invalid address");
    require(_quantity > 0 && _quantity <= tokensRemaining(), "invalid quantity");
    _safeMint(_to, _quantity);
  }

  function setBurnContractAddress(address _burnContractAddress) external onlyOwner {
    burnContractAddress = _burnContractAddress;
  }

  function burn(uint256[] calldata _tokenIds) external {
    require(msg.sender == burnContractAddress, "illegal operation");

    for (uint256 i = 0; i < _tokenIds.length; i++) {
      _burn(_tokenIds[i]);
    }
  }
}