/***
 *                 _                 _
 *     ___   __ _ | |_  __ _   __ _ (_)
 *    / __| / _` || __|/ _` | / _` || |
 *    \__ \| (_| || |_| (_| || (_| || |
 *    |___/ \__,_| \__|\__,_| \__, ||_|
 *                               |_|
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./AccessControl.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";

contract BottzArmy is ERC721A, Ownable, AccessControl, ReentrancyGuard {
  using Strings for uint256;

  uint256 private constant maxSupply = 5000;
  uint256 private maxSupplyWl = 3000;
  uint256 private maxSupplyTotal = 5000;
  uint256 private wlPrice = 0.07 ether;
  uint256 private publicPrice = 0.1 ether;
  uint256 public maxPerWallet = 3;
  bool public isTransferPaused = false;
  bool public isMintPaused = false;
  bool public wlStarted = false;
  bool public publicStarted = false;
  bool private isRevealed = false;
  string private uriPrefix;
  string private hiddenMetadataURI;
  bytes32 public wlMerkleRoot;
  address private withdrawWallet;
  mapping(address => uint256) private wlMinted;

  constructor() ERC721A("BOTTZ Army", "BOT") {
    _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
  }

  modifier mintCompliance(uint256 _mintAmount, uint256 _totalAmount) {
    require(!isMintPaused, "Minting is paused.");
    require((totalSupply() + _mintAmount) <= _totalAmount, "Mint amount exceeds allocated supply.");
    _;
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, AccessControl) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "No data exists for provided tokenId.");

    if (isRevealed == false) {
      return hiddenMetadataURI;
    }

    return bytes(uriPrefix).length > 0 ? string(abi.encodePacked(uriPrefix, tokenId.toString(), ".json")) : "";
  }

  function wlMint(uint256 _mintAmount, bytes32[] calldata _merkleProof)
    external
    payable
    mintCompliance(_mintAmount, maxSupplyWl)
  {
    uint256 minted = wlMinted[_msgSender()];
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));

    require(wlStarted, "Whitelist sale is paused.");
    require(msg.value >= (wlPrice * _mintAmount), "Insufficient balance to mint.");
    require(
      (minted + _mintAmount) <= maxPerWallet,
      "Selected number of mints will exceed the maximum amount of allowed per wallet."
    );
    require(
      MerkleProof.verify(_merkleProof, wlMerkleRoot, leaf),
      "Invalid proof, this wallet is not allowed to mint using Whitelist."
    );

    wlMinted[_msgSender()] = minted + _mintAmount;

    _safeMint(_msgSender(), _mintAmount);
  }

  function publicMint(uint256 _mintAmount) external payable mintCompliance(_mintAmount, maxSupplyTotal) {
    require(publicStarted, "Public sale is paused.");
    require(msg.value >= (publicPrice * _mintAmount), "Insufficient balance to mint.");

    _safeMint(_msgSender(), _mintAmount);
  }

  function getWlMinted(address _wallet) external view returns (uint256) {
    return wlMinted[_wallet];
  }

  // admin
  function mintFor(uint256 _mintAmount, address _receiver)
    external
    mintCompliance(_mintAmount, maxSupplyTotal)
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    _safeMint(_receiver, _mintAmount);
  }

  function updateMaxSupplyWl(uint256 _number) external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(_number <= maxSupplyTotal, "Whitelist supply can not exceed total supply.");

    maxSupplyWl = _number;
  }

  function updateMaxSupplyTotal(uint256 _number) external onlyRole(DEFAULT_ADMIN_ROLE) {
    // collection can be capped, if needed, but can never increase from initial total
    require(_number <= maxSupply, "Public supply can not exceed total defined.");
    require(_number >= totalSupply(), "Supply can not be less than already minted.");

    maxSupplyTotal = _number;
  }

  function updateWlPrice(uint256 _number) external onlyRole(DEFAULT_ADMIN_ROLE) {
    wlPrice = _number;
  }

  function updatePublicPrice(uint256 _number) external onlyRole(DEFAULT_ADMIN_ROLE) {
    publicPrice = _number;
  }

  function updateMaxPerWallet(uint256 _number) external onlyRole(DEFAULT_ADMIN_ROLE) {
    maxPerWallet = _number;
  }

  function toggleTransfer(bool _state) external onlyRole(DEFAULT_ADMIN_ROLE) {
    isTransferPaused = _state;
  }

  function toggleMint(bool _state) external onlyRole(DEFAULT_ADMIN_ROLE) {
    isMintPaused = _state;
  }

  function toggleWlSale(bool _state) external onlyRole(DEFAULT_ADMIN_ROLE) {
    wlStarted = _state;
  }

  function togglePublicSale(bool _state) external onlyRole(DEFAULT_ADMIN_ROLE) {
    publicStarted = _state;
  }

  function reveal() external onlyRole(DEFAULT_ADMIN_ROLE) {
    isRevealed = true;
  }

  function updateURIPrefix(string calldata _uriPrefix) external onlyRole(DEFAULT_ADMIN_ROLE) {
    uriPrefix = _uriPrefix;
  }

  function updateHiddenMetadataURI(string memory _hiddenMetadataURI) external onlyRole(DEFAULT_ADMIN_ROLE) {
    hiddenMetadataURI = _hiddenMetadataURI;
  }

  function updateWlRoot(bytes32 _merkleRoot) external onlyRole(DEFAULT_ADMIN_ROLE) {
    wlMerkleRoot = _merkleRoot;
  }

  function updateWithdrawWallet(address _withdrawWallet) external onlyRole(DEFAULT_ADMIN_ROLE) {
    withdrawWallet = _withdrawWallet;
  }

  function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant {
    require(withdrawWallet != address(0), "withdraw wallet is not set.");

    (bool success, ) = payable(withdrawWallet).call{value: address(this).balance}("");

    require(success, "Withdraw failed.");
  }
}
