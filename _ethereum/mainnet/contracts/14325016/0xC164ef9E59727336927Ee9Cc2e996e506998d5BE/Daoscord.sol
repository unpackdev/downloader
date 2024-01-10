// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "./Ownable.sol";
import "./ERC721.sol";
import "./Counters.sol";
import "./console.sol";

contract Daoscord is Ownable, ERC721 {
  using Strings for uint256;

  using Counters for Counters.Counter;
  Counters.Counter private _tokenSupply;

  string public collectionName;
  string public collectionSymbol;

  uint256 public constant MINT_LIMIT_PER_TX = 8;
  uint256 public constant TOTAL_SUPPLY = 6501;
  uint256 public constant FREE_MINTS = 1001;

  bool public active = false;
  bool public revealed = false;

  uint256 public tokenPrice = 0.0175 ether;

  string public nonReavealedURI;
  string public constant baseExtension = '.json';

  string _baseTokenURI;
  address _proxyRegistryAddress;

  constructor(
    address proxyRegistryAddress,
    string memory _initBaseURI,
    string memory _initNotRevealedUri
  ) ERC721('DAOscord', 'DAOS') {
    collectionName = name();
    collectionSymbol = symbol();
    nonReavealedURI = _initNotRevealedUri;
    _baseTokenURI = _initBaseURI;
    _proxyRegistryAddress = proxyRegistryAddress;
    _tokenSupply.increment();
    _safeMint(msg.sender, 0);
  }

  function freeMint(uint256 amount) external {
    require(active, 'Token sale is not currently active');
    require(amount <= MINT_LIMIT_PER_TX, 'Cannot mint more than 8 tokens per transation');
    uint256 supply = _tokenSupply.current();
    require(supply + amount <= FREE_MINTS, 'Not enough free mints remaining');

    for (uint256 i = 0; i < amount; i++) {
      _tokenSupply.increment();
      _safeMint(msg.sender, supply + i);
    }
  }

  function publicMint(uint256 amount) external payable {
    require(active, 'Token sale is not currently active');
    require(amount <= MINT_LIMIT_PER_TX, 'Cannot mint more than 8 tokens per transation');

    uint256 supply = _tokenSupply.current();
    require(supply + amount <= TOTAL_SUPPLY, 'Not enough tokens are remaining in the supply');

    require(tokenPrice * amount <= msg.value, 'Not enough ethereum sent to mint');

    for (uint256 i = 0; i < amount; i++) {
      _tokenSupply.increment();
      _safeMint(msg.sender, supply + i);
    }
  }

  function mintOwner(address to, uint256 amount) external onlyOwner {
    uint256 supply = _tokenSupply.current();
    require(supply + amount <= TOTAL_SUPPLY, 'Cannot mint more than the total supply');

    for (uint256 i = 0; i < amount; i++) {
      _tokenSupply.increment();
      _safeMint(to, supply + i);
    }
  }

  function reveal() external onlyOwner {
    revealed = true;
  }

  function setTokenPrice(uint256 newPrice) external onlyOwner {
    require(newPrice > 0, 'New price must be greater than 0');
    tokenPrice = newPrice;
  }

  function toggleActiveState() external onlyOwner {
    active = !active;
  }

  function setBaseURI(string memory newBaseURI) external onlyOwner {
    _baseTokenURI = newBaseURI;
  }

  function setNonRevealed(string memory newNonRevealedURI) external onlyOwner {
    nonReavealedURI = newNonRevealedURI;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');

    if (revealed == false) {
      return nonReavealedURI;
    }

    string memory currentBaseURI = _baseURI();
    return
      bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : '';
  }

  function currentSupply() public view returns (uint256) {
    return _tokenSupply.current();
  }

  function _baseURI() internal view override returns (string memory) {
    return _baseTokenURI;
  }

  function setProxyRegistryAddress(address proxyRegistryAddress) external onlyOwner {
    _proxyRegistryAddress = proxyRegistryAddress;
  }

  function isApprovedForAll(address owner, address operator) public view override returns (bool) {
    // Whitelist OpenSea proxy contract for easy trading.
    ProxyRegistry proxyRegistry = ProxyRegistry(_proxyRegistryAddress);
    if (address(proxyRegistry.proxies(owner)) == operator) {
      return true;
    }
    return super.isApprovedForAll(owner, operator);
  }

  receive() external payable {}

  function withdraw() external onlyOwner {
    (bool success, ) = payable(owner()).call{value: address(this).balance}('');
    require(success, 'Withdrawal failed');
  }
}

contract OwnableDelegateProxy {}

contract ProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}
