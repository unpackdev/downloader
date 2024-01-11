// SPDX-License-Identifier: UNLICENCED

pragma solidity ^0.8.7;

import "./ERC721Enumerable.sol";
import "./ERC2981.sol";
import "./PaymentSplitter.sol";

import "./Ownable.sol";

import "./Address.sol";
import "./MerkleProof.sol";

contract CSSABoars is ERC721, ERC2981, PaymentSplitter, Ownable {

  address public proxyRegistryAddress;

  bool public isWhitelistMintingOpened;
  bool public isPublicMintingOpened;

  bytes32 public merkleRoot;

  string public baseURI;

  event WhitelistMintFlipped(bool wlMint, address origin);
  event PublicMintFlipped(bool publicMint, address origin);
  event BaseURIUpdated(string newURI, address origin);
  event ProxyRegistryAddressUpdated(address newAddress, address origin);
  event MerkleRootUpdated(bytes32 newAddress, address origin);
  event DefaultRoyaltySet(address receiver, uint96 feeNumerator, address origin);

  struct Family {
    uint96 presalePrice;
    uint96 publicPrice;
    uint16 airdropSupply;
    uint16 maxSupply;
    uint16 currentIndex;
    uint16 offset;
  }

  Family[] public families;

  constructor(
    address owner,
    address[] memory payees,
    uint256[] memory shares,
    string memory _uri,
    address _proxy)
    ERC721("CSSA Boars","CSSABOAR")
    PaymentSplitter(payees, shares)
    {
      require(owner != address(0), "Please provide a valid owner");
      baseURI = _uri;
      setDefaultRoyalty(owner, 1000); // 10% fees
      transferOwnership(owner);
      proxyRegistryAddress = _proxy;

      // Goal Keeper - Index 0
      families.push(Family({
        publicPrice: 150_000_000 gwei,
        presalePrice: 100_000_000 gwei,
        airdropSupply: 44,
        maxSupply: 2500,
        currentIndex: 0,
        offset: 0
        }));

      // Defender - Index 1
      families.push(Family({
        publicPrice: 50_000_000 gwei,
        presalePrice: 30_000_000 gwei,
        airdropSupply: 44,
        maxSupply: 2500,
        currentIndex: 0,
        offset: 2500
        }));

      // Midfielder - Index 2
      families.push(Family({
        publicPrice: 100_000_000 gwei,
        presalePrice: 70_000_000 gwei,
        airdropSupply: 44,
        maxSupply: 2500,
        currentIndex: 0,
        offset: 5000
        }));

      // Stricker - Index 3
      families.push(Family({
        publicPrice: 200_000_000 gwei,
        presalePrice: 150_000_000 gwei,
        airdropSupply: 44,
        maxSupply: 2500,
        currentIndex: 0,
        offset: 7500
        }));

      // Staff - Index 4
      families.push(Family({
        publicPrice: 250_000_000 gwei,
        presalePrice: 200_000_000 gwei,
        airdropSupply: 46,
        maxSupply: 1011,
        currentIndex: 0,
        offset: 10000
        }));
  }

  //
  // Collection settings
  //

  function setBaseURI(string calldata _newBaseURI) external onlyOwner {
    baseURI = _newBaseURI;
    emit BaseURIUpdated(_newBaseURI, msg.sender);
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  // 10% => feeNumerator = 1000
  function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
    _setDefaultRoyalty(receiver, feeNumerator);
    emit DefaultRoyaltySet(receiver, feeNumerator, msg.sender);
  }

  // OpenSea specifics
  function isApprovedForAll(address _owner, address operator) public view override returns (bool) {
    if (proxyRegistryAddress == address(0)) return false;
    MarketplaceProxyRegistry proxyRegistry = MarketplaceProxyRegistry(proxyRegistryAddress);
    if (address(proxyRegistry.proxies(_owner)) == operator) return true;
    return super.isApprovedForAll(_owner, operator);
  }

  function setProxyRegistry(address _proxyRegistryAddress) public onlyOwner {
    proxyRegistryAddress = _proxyRegistryAddress;
    emit ProxyRegistryAddressUpdated(_proxyRegistryAddress, msg.sender);
  }

  // Contract metadata URI - Support for OpenSea: https://docs.opensea.io/docs/contract-level-metadata
  function contractURI() public view returns (string memory) {
      return string(abi.encodePacked(_baseURI(), "contract.json"));
  }

  //
  // Mint
  //

  function discount(uint256 count) public pure returns (uint256) {
    return (count/3) * 0.025 ether;
  }

  function calculatePublicPrice(uint16[] memory _families, uint16[] memory _count) public view returns(uint256 price) {
    uint256 totalCount = 0;
    for(uint256 i = 0; i < _families.length; i++) {
      totalCount += _count[i];
      price += families[_families[i]].publicPrice * _count[i];
    }
    price -= discount(totalCount);
  }

  function mint(uint16[] memory _families, uint16[] memory _count) external payable {
    require(isPublicMintingOpened, "Public minting is closed");

    uint256 price = calculatePublicPrice(_families, _count);
    require(price == msg.value, "Invalid amount sent");

    _batchMint(msg.sender, _families, _count);
  }

  function flipPublicMint() external onlyOwner {
    isPublicMintingOpened = !isPublicMintingOpened;
    emit PublicMintFlipped(isPublicMintingOpened, msg.sender);
  }

  function _batchMint(address to, uint16[] memory family, uint16[] memory count) private {
    for (uint i = 0; i < count.length; i++) {
      Family storage currentFamily = families[family[i]];

      require(currentFamily.currentIndex +
              currentFamily.airdropSupply +
              count[i] <= currentFamily.maxSupply, "Sold out");

      uint localIndex = currentFamily.currentIndex;
      currentFamily.currentIndex += count[i];

      for(uint j = 0; j < count[i]; j++) {
        localIndex++;
        _safeMint(to, currentFamily.offset + localIndex);
      }
    }
  }

  function airdrop(address to, uint16[] memory _families, uint16[] memory _count) external onlyOwner {
    for (uint i = 0; i < _count.length; i++) {
      Family storage currentFamily = families[_families[i]];
      currentFamily.airdropSupply -= _count[i];
    }
    _batchMint(to, _families, _count);
  }

  //
  // Whitelist management
  //

  function flipWhiteListMint() external onlyOwner{
    isWhitelistMintingOpened = !isWhitelistMintingOpened;
    emit WhitelistMintFlipped(isWhitelistMintingOpened, msg.sender);
  }

  // Merkle tree whitelist

  function calculatePresalePrice(uint16[] memory _families, uint16[] memory _count) public view returns(uint256 price) {
    for(uint256 i = 0; i < _families.length; i++) {
      price += families[_families[i]].presalePrice * _count[i];
    }
  }

  function isWhitelisted(address _a, bytes32[] memory _proof) public view returns (bool) {
    bytes32 leaf = keccak256(abi.encodePacked(_a));
    return MerkleProof.verify(_proof, merkleRoot, leaf);
  }

  function merkleTreeWLMint(uint16[] memory _families, uint16[] memory _count, bytes32[] memory _proof) external payable {
    require(isWhitelistMintingOpened, "Whitelist minting is closed");

    require(isWhitelisted(msg.sender, _proof), "Address not whitelisted");

    uint256 price = calculatePresalePrice(_families, _count);
    require(price == msg.value, "Invalid amount sent");

    _batchMint(msg.sender, _families, _count);
  }

  function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
    merkleRoot = _merkleRoot;
    emit MerkleRootUpdated(_merkleRoot, msg.sender);
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC2981) returns (bool) {
    return super.supportsInterface(interfaceId);
  }
}

contract OwnableDelegateProxy {}

contract MarketplaceProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}