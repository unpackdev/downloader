// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";

contract Love15 is ERC721A, Ownable, ReentrancyGuard {
  using Strings for uint256;

  uint256 private maxSupplyTotal = 25;
  uint256 private maxSupplyPrivate = 5;
  uint256 private pricePublic = 0.1 ether;
  uint256 private pricePrivate = 0.08 ether;
  uint256 private constant maxPerTx = 2;
  uint256 private maxPerWallet = 2;
  bool private paused = true;
  bool private revealed = false;
  bool private privateStarted = true;
  bool private publicStarted = false;
  string private uriPrefix;
  string private hiddenMetadataURI;
  mapping(address => uint256) private mintedWallets;
  address private withdrawWallet;
  bytes32 private merkleRoot;

  constructor(string memory _hiddenMetadataURI) ERC721A("15 Love", "15LV") {
    setHiddenMetadataURI(_hiddenMetadataURI);
  }

  modifier mintCompliance(uint256 _mintAmount, uint256 _totalAmount) {
    require(!paused, "Minting is paused.");
    require(totalSupply() + _mintAmount <= _totalAmount, "Mint amount exceeds total supply.");
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount, uint256 price) {
    require(msg.value >= price * _mintAmount, "Insufficient balance to mint.");
    _;
  }

  function setHiddenMetadataURI(string memory _hiddenMetadataURI) private {
    hiddenMetadataURI = _hiddenMetadataURI;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "No data exists for provided tokenId.");

    if (revealed == false) {
      return hiddenMetadataURI;
    }

    string memory currentBaseURI = _baseURI();

    return
      bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json")) : "";
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
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
      minted + _mintAmount <= maxPerWallet,
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
    onlyOwner
  {
    _safeMint(_receiver, _mintAmount);
  }

  function withdraw() public onlyOwner nonReentrant {
    (bool success, ) = payable(withdrawWallet).call{value: address(this).balance}("");

    require(success, "Withdraw failed.");
  }

  function updateWithdrawWallet(address _withdrawWallet) public onlyOwner {
    withdrawWallet = _withdrawWallet;
  }

  function updateMaxSupplyTotal(uint256 _number) public onlyOwner {
    maxSupplyTotal = _number;
  }

  function updateMaxSupplyPrivate(uint256 _number) public onlyOwner {
    require(_number <= maxSupplyTotal, "Private supply can not exceed total supply.");

    maxSupplyPrivate = _number;
  }

  function updateMaxPerWallet(uint256 _number) public onlyOwner {
    maxPerWallet = _number;
  }

  function updateURIPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function reveal() public onlyOwner {
    revealed = true;
  }

  function togglePause(bool _state) public onlyOwner {
    paused = _state;
  }

  function togglePrivateSale(bool _state) public onlyOwner {
    privateStarted = _state;
  }

  function togglePublicSale(bool _state) public onlyOwner {
    publicStarted = _state;
  }

  function updateMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }
}
