// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./AccessControl.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";

contract Love15 is ERC721A, Ownable, AccessControl, ReentrancyGuard {
  using Strings for uint256;

  uint256 private constant maxSupply = 7777;
  uint256 private maxSupplyTotal = 7777;
  uint256 private maxSupplyPrivate = 4000;
  uint256 private pricePrivate = 0.079 ether;
  uint256 private pricePublic = 0.089 ether;
  uint256 private constant maxPerTx = 2;
  uint256 private maxPerWallet = 2;
  bool private revealed = false;
  bool public paused = true;
  bool public privateStarted = false;
  bool public publicStarted = false;
  string private uriPrefix;
  string private hiddenMetadataURI;
  mapping(address => uint256) private mintedWallets;
  address private withdrawWallet;
  bytes32 private merkleRoot;

  constructor(string memory _hiddenMetadataURI) ERC721A("15 Love", "15LV") {
    _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    setHiddenMetadataURI(_hiddenMetadataURI);
  }

  modifier mintCompliance(uint256 _mintAmount, uint256 _totalAmount) {
    require(!paused, "Minting is paused.");
    require((totalSupply() + _mintAmount) <= _totalAmount, "Mint amount exceeds total supply.");
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount, uint256 price) {
    require(msg.value >= (price * _mintAmount), "Insufficient balance to mint.");
    _;
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, AccessControl) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  function setHiddenMetadataURI(string memory _hiddenMetadataURI) public {
    hiddenMetadataURI = _hiddenMetadataURI;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "No data exists for provided tokenId.");

    if (revealed == false) {
      return hiddenMetadataURI;
    }

    return bytes(uriPrefix).length > 0 ? string(abi.encodePacked(uriPrefix, tokenId.toString(), ".json")) : "";
  }

  function mint(uint256 _mintAmount)
    public
    payable
    mintCompliance(_mintAmount, maxSupplyTotal)
    mintPriceCompliance(_mintAmount, pricePublic)
  {
    require(publicStarted, "Public sale is paused.");

    _safeMint(_msgSender(), _mintAmount);
  }

  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof)
    public
    payable
    mintCompliance(_mintAmount, maxSupplyPrivate)
    mintPriceCompliance(_mintAmount, pricePrivate)
  {
    uint256 minted = mintedWallets[_msgSender()];

    require(privateStarted, "Private sale is paused.");
    require(_mintAmount <= maxPerTx, "Mint amount exceeds max allowed per transaction.");
    require(
      (minted + _mintAmount) <= maxPerWallet,
      "Selected number of mints will exceed the maximum amount of allowed per wallet."
    );

    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));

    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid proof, this wallet is not whitelisted.");

    mintedWallets[_msgSender()] = minted + _mintAmount;

    _safeMint(_msgSender(), _mintAmount);
  }

  function mintFor(address _receiver, uint256 _mintAmount)
    public
    mintCompliance(_mintAmount, maxSupplyTotal)
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    _safeMint(_receiver, _mintAmount);
  }

  function withdraw() public onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant {
    require(withdrawWallet != address(0), "Withdraw wallet is not set.");

    (bool success, ) = payable(withdrawWallet).call{value: address(this).balance}("");

    require(success, "Withdraw failed.");
  }

  function updateWithdrawWallet(address _withdrawWallet) public onlyRole(DEFAULT_ADMIN_ROLE) {
    withdrawWallet = _withdrawWallet;
  }

  function updateMaxSupplyTotal(uint256 _number) public onlyRole(DEFAULT_ADMIN_ROLE) {
    // added this check so that collection can be under capped if needed but can never increase from initial total
    require(_number <= maxSupply, "Public supply can not exceed total defined.");

    maxSupplyTotal = _number;
  }

  function updateMaxSupplyPrivate(uint256 _number) public onlyRole(DEFAULT_ADMIN_ROLE) {
    require(_number <= maxSupplyTotal && _number >= totalSupply(), "Invalid private supply.");

    maxSupplyPrivate = _number;
  }

  function updateMaxPerWallet(uint256 _number) public onlyRole(DEFAULT_ADMIN_ROLE) {
    maxPerWallet = _number;
  }

  function updateURIPrefix(string memory _uriPrefix) public onlyRole(DEFAULT_ADMIN_ROLE) {
    uriPrefix = _uriPrefix;
  }

  function reveal() public onlyRole(DEFAULT_ADMIN_ROLE) {
    revealed = true;
  }

  function togglePause(bool _state) public onlyRole(DEFAULT_ADMIN_ROLE) {
    paused = _state;
  }

  function togglePrivateSale(bool _state) public onlyRole(DEFAULT_ADMIN_ROLE) {
    privateStarted = _state;
  }

  function togglePublicSale(bool _state) public onlyRole(DEFAULT_ADMIN_ROLE) {
    publicStarted = _state;
  }

  function updateMerkleRoot(bytes32 _merkleRoot) public onlyRole(DEFAULT_ADMIN_ROLE) {
    merkleRoot = _merkleRoot;
  }
}
