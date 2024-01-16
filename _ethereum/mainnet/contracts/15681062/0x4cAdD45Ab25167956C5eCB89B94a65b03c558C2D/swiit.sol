// SPDX-License-Identifier: UNLICENCED

pragma solidity ^0.8.7;

import "./ERC721A.sol";
import "./ERC2981.sol";

import "./Ownable.sol";

import "./Address.sol";
import "./MerkleProof.sol";

contract Swiit is ERC721A, ERC2981, Ownable {

  bool public isWhitelistMintingOpened;
  bool public isPublicMintingOpened;

  uint16 public constant MAXCOLLECTIONSIZE = 5555;
  uint16 public WLLIMIT = 555;
  uint16 public publicMintLimit = 10;
  uint16 public presaleMintLimit = 10;

  bytes32 public merkleRoot;

  string public baseURI;
  address public proxyRegistryAddress;

  event WhitelistMintFlipped(bool wlMint);
  event PublicMintFlipped(bool publicMint);
  event BaseURIUpdated(string newURI);
  event WhiteListLimitUpdated(uint16 newLimit);
  event PresaleMintLimitUpdated(uint16 newLimit);
  event PublicMintLimitUpdated(uint16 newLimit);
  event Withdrawn(uint256 amount);
  event DefaultRoyaltySet(address receiver, uint96 feeNumerator);

  constructor(
    address owner,
    string memory _uri,
    address proxy)
    ERC721A("SWIIT GENESIS","SWT")
    {
      require(owner != address(0), "Please provide a valid owner");
      baseURI = _uri;
      setDefaultRoyalty(owner, 1055); // 10.55% fees
      transferOwnership(owner);
      proxyRegistryAddress = proxy;
  }

  function _startTokenId() internal view virtual override returns (uint256) {
      return 1;
  }

  //
  // Mint
  //

  function mint(uint16 count) external payable {
    require(msg.value == publicPrice(count),"Invalid amount");
    require(isPublicMintingOpened, "Public minting is closed");
    require(_numberMinted(msg.sender) + count <= publicMintLimit, "Limit per wallet exeeded");

    _batchMint(msg.sender, count);
  }

  function publicPrice(uint16 count) public pure returns (uint256) {
    uint ratio = 10000;
    if (count > 2) {
      ratio = 8945;
    }
    return (0.15 ether * count * ratio) / 10000;
  }

  function flipPublicMint() external onlyOwner {
    isPublicMintingOpened = !isPublicMintingOpened;
    emit PublicMintFlipped(isPublicMintingOpened);
  }

  function updatePublicMintLimit(uint16 newLimit) external onlyOwner {
    publicMintLimit = newLimit;
    emit PublicMintLimitUpdated(newLimit);
  }

  function _batchMint(address to, uint16 count) private {
    require(totalSupply() + count <= MAXCOLLECTIONSIZE, "Collection is sold out");

    _safeMint(to, count);
  }

  function airdrop(address to, uint16 count) external onlyOwner {
    _batchMint(to, count);
  }

  //
  // Whitelist management
  //

  function flipWhiteListMint() external onlyOwner{
    isWhitelistMintingOpened = !isWhitelistMintingOpened;
    emit WhitelistMintFlipped(isWhitelistMintingOpened);
  }

  function updatePresaleMintLimit(uint16 newLimit) external onlyOwner {
    presaleMintLimit = newLimit;
    emit PresaleMintLimitUpdated(newLimit);
  }

  function presalePrice(uint16 count) public pure returns (uint256){
    return 0.10 ether * count;
  }

  function setWLLimit(uint16 _limit) external onlyOwner {
    WLLIMIT = _limit;
    emit WhiteListLimitUpdated(_limit);
  }

  function isWhitelisted(address _a, bytes32[] memory _proof) public view returns (bool) {
    bytes32 leaf = keccak256(abi.encodePacked(_a));
    return MerkleProof.verify(_proof, merkleRoot, leaf);
  }

  function merkleTreeWLMint(uint16 _count, bytes32[] memory _proof) external payable {
    require(isWhitelistMintingOpened, "Whitelist minting is closed");
    require(msg.value == presalePrice(_count),"Invalid amount sent");
    require(isWhitelisted(msg.sender, _proof), "Address not whitelisted");
    require(_numberMinted(msg.sender) + _count <= presaleMintLimit, "Limit per wallet exeeded");
    require(totalSupply() + _count <= WLLIMIT, "Presale is sold out");

    _batchMint(msg.sender, _count);
  }

  function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
    merkleRoot = _merkleRoot;
  }

  //
  // Fund management
  //

  function withdraw() external onlyOwner{
    uint256 amount = address(this).balance;
    Address.sendValue(payable(owner()), amount);
    emit Withdrawn(amount);
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  //
  // Collection settings
  //

  function setBaseURI(string calldata _newBaseURI) external onlyOwner {
    baseURI = _newBaseURI;
    emit BaseURIUpdated(_newBaseURI);
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  // 10% => feeNumerator = 1000
  function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner{
    _setDefaultRoyalty(receiver, feeNumerator);
    emit DefaultRoyaltySet(receiver, feeNumerator);
  }

  // OpenSea specifics
  function isApprovedForAll(address _owner, address operator) public view override returns (bool) {
    MarketplaceProxyRegistry proxyRegistry = MarketplaceProxyRegistry(proxyRegistryAddress);
    if (address(proxyRegistry.proxies(_owner)) == operator) return true;
    return super.isApprovedForAll(_owner, operator);
  }

  function setProxyRegistry(address _proxyRegistryAddress) public onlyOwner {
    proxyRegistryAddress = _proxyRegistryAddress;
  }
}

contract OwnableDelegateProxy {}

contract MarketplaceProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}