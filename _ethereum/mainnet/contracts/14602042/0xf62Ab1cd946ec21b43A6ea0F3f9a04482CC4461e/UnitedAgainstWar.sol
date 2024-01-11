// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ERC721A.sol";
import "./MerkleProof.sol";
import "./Ownable.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}

contract UnitedAgainstWar is ERC721A, Ownable {
  string public baseURI;
  bytes32 public merkleRoot;

  bool public paused = false;

  uint256 public maxSupply = 11111;
  uint256 public maxPerTx = 5;
  uint256 public maxPerWallet = 10;

  bool public publicActive = false;
  uint256 public publicPrice = 0.05 ether;

  bool public whitelistActive = false;
  uint256 public whitelistPrice = 0.04 ether;

  address internal proxyRegistryAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;

  constructor() ERC721A("United Against War", "UAW") {}

  /**
   * @notice Mint token(s) to your own address
   */
  function publicMint(uint256 _quantity) external payable {
    address _to = msg.sender;
    uint256 _value = msg.value;

    uint256 _balanceOf = balanceOf(_to);
    uint256 _totalSupply = totalSupply();

    require(!paused, "Contract is paused");
    require(publicActive, "Public sale is not active");
    require(_quantity > 0, "Can't mint 0 tokens");
    require(tx.origin == _to, "Humans only please");
    require(maxSupply >= _totalSupply + _quantity, "Exceeds maximum token supply");
    require(_balanceOf + _quantity <= maxPerWallet, "Exceeds maximum tokens per wallet");
    require(maxPerTx >= _quantity, "Exceeds maximum tokens per transaction");
    require(_quantity * publicPrice <= _value, "Invalid funds provided");

    _safeMint(_to, _quantity);
  }

  /**
   * @notice Whitelist mint token(s) to your own address
   */
  function whitelistMint(uint256 _quantity, bytes32[] calldata _merkleProof) external payable {
    address _to = msg.sender;
    uint256 _value = msg.value;

    uint256 _balanceOf = balanceOf(_to);
    uint256 _totalSupply = totalSupply();

    require(!paused, "Contract is paused");
    require(whitelistActive, "Whitelist sale is not active");
    require(_quantity > 0, "Can't mint 0 tokens");
    require(tx.origin == _to, "Humans only please");
    require(maxSupply >= _totalSupply + _quantity, "Exceeds maximum token supply");
    require(_balanceOf + _quantity <= maxPerWallet, "Exceeds maximum tokens per wallet");
    require(maxPerTx >= _quantity, "Exceeds maximum tokens per transaction");
    require(_quantity * whitelistPrice <= _value, "Invalid funds provided");
    require(isValidMerkleProof(_merkleProof, merkleRoot, _to), "Invalid merkle proof");

    _safeMint(_to, _quantity);
  }

  /**
   * @notice Mint to reserve token(s) for giveaways, collabs, personal use, etc. (only for owner)
   */
  function adminMint(uint256 _quantity) external onlyOwner {
    address _to = msg.sender;

    uint256 _totalSupply = totalSupply();

    require(_quantity > 0, "Can't mint 0 tokens");
    require(maxSupply >= _totalSupply + _quantity, "Exceeds maximum token supply");

    _safeMint(_to, _quantity);
  }

  /**
   * @notice Mint and gift token(s) to another address (only for owner)
   */
  function giftMint(address _to, uint256 _quantity) external onlyOwner {
    uint256 _totalSupply = totalSupply();

    require(_quantity > 0, "Can't mint 0 tokens");
    require(maxSupply >= _totalSupply + _quantity, "Exceeds maximum token supply");

    _safeMint(_to, _quantity);
  }

  /**
   * Overwrite _startTokenId function to start token id at 1
   */
  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

  /**
   * @notice Set paused state (only for owner)
   */
  function setPaused(bool _newPaused) external onlyOwner {
    paused = _newPaused;
  }

  /**
   * @notice Set public active state (only for owner)
   */
  function setPublicActive(bool _newActive) external onlyOwner {
    publicActive = _newActive;
  }

  /**
   * @notice Set whitelist active state (only for owner)
   */
  function setWhitelistActive(bool _newActive) external onlyOwner {
    whitelistActive = _newActive;
  }

  /**
   * @notice Set public token price in wei (only for owner)
   */
  function setPublicPrice(uint256 _newPrice) external onlyOwner {
    publicPrice = _newPrice;
  }

  /**
   * @notice Set whitelist token price in wei (only for owner)
   */
  function setWhitelistPrice(uint256 _newPrice) external onlyOwner {
    whitelistPrice = _newPrice;
  }

  /**
   * @notice Set merkle root (only for owner)
   */
  function setMerkleRoot(bytes32 _newMerkleRoot) external onlyOwner {
    merkleRoot = _newMerkleRoot;
  }

  /**
   * Validate merkle proof
   */
  function isValidMerkleProof(
    bytes32[] calldata _proof,
    bytes32 _root,
    address _leaf
  ) internal pure returns (bool) {
    return (MerkleProof.verify(_proof, _root, keccak256(abi.encodePacked(_leaf))));
  }

  /**
   * @notice Set maximum tokens per transaction (only for owner)
   */
  function setMaxPerTx(uint256 _newMaxPerTx) external onlyOwner {
    maxPerTx = _newMaxPerTx;
  }

  /**
   * @notice Set maximum tokens per wallet (only for owner)
   */
  function setMaxPerWallet(uint256 _newMaxPerWallet) external onlyOwner {
    maxPerWallet = _newMaxPerWallet;
  }

  /**
   * @notice Set proxy registry address, mainly for OpenSea (only for owner)
   */
  function setProxyRegistryAddress(address _newProxyRegistryAddress) external onlyOwner {
    proxyRegistryAddress = _newProxyRegistryAddress;
  }

  /**
   * @notice Set base URI (only for owner)
   */
  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  /**
   * Overwrite _baseURI function to update the base token URI
   */
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  /**
   * @notice Withdraw balance from contract (only for owner)
   */
  function withdraw() external onlyOwner {
    address _owner = msg.sender;

    (bool success, ) = payable(_owner).call{value: address(this).balance}("");
    require(success, "Transfer failed");
  }

  /**
   * Overwrite renounceOwnership function to disable renouncing ownership (only for owner)
   */
  function renounceOwnership() public view override onlyOwner {
    revert("Can't leave the contract without an owner");
  }

  /**
   * @notice Overwrite isApprovedForAll function for Opensea proxy contract
   */
  function isApprovedForAll(address _owner, address _operator) public view override returns (bool) {
    ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);

    if (address(proxyRegistry.proxies(_owner)) == _operator) {
      return true;
    }

    return super.isApprovedForAll(_owner, _operator);
  }
}
