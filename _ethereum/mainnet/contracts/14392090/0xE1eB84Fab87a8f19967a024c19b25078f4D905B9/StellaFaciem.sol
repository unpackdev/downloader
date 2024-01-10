// SPDX-License-Identifier: MIT

// ███████╗████████╗███████╗██╗     ██╗      █████╗         ███████╗ █████╗  ██████╗██╗███████╗███╗   ███╗
// ██╔════╝╚══██╔══╝██╔════╝██║     ██║     ██╔══██╗        ██╔════╝██╔══██╗██╔════╝██║██╔════╝████╗ ████║
// ███████╗   ██║   █████╗  ██║     ██║     ███████║        █████╗  ███████║██║     ██║█████╗  ██╔████╔██║
// ╚════██║   ██║   ██╔══╝  ██║     ██║     ██╔══██║        ██╔══╝  ██╔══██║██║     ██║██╔══╝  ██║╚██╔╝██║
// ███████║   ██║   ███████╗███████╗███████╗██║  ██║        ██║     ██║  ██║╚██████╗██║███████╗██║ ╚═╝ ██║
// ╚══════╝   ╚═╝   ╚══════╝╚══════╝╚══════╝╚═╝  ╚═╝        ╚═╝     ╚═╝  ╚═╝ ╚═════╝╚═╝╚══════╝╚═╝     ╚═╝       

pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

contract StellaFaciem is ERC721A, Ownable, ReentrancyGuard {

  using Strings for uint256;

  bytes32 public merkleRoot;
  mapping(address => bool) public whitelistClaimed;

  string public uriPrefix = "";
  string public uriSuffix = "";
  string public hiddenMetadataUri;
  
  uint256 public cost;
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;
  uint256 public maxMintPerAddr;
  uint256 public maxReserve;

  bool public paused = true;
  bool public whitelistMintEnabled = false;
  bool public revealed = false;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _maxSupply,
    uint256 _maxReserve,
    uint256 _maxMintAmountPerTx,
    uint256 _maxMintPerAddr,
    string memory _hiddenMetadataUri
  ) ERC721A(_tokenName, _tokenSymbol) {
    cost = _cost;
    maxSupply = _maxSupply;
    maxReserve = _maxReserve;
    maxMintPerAddr = _maxMintPerAddr;
    maxMintAmountPerTx = _maxMintAmountPerTx;
    setHiddenMetadataUri(_hiddenMetadataUri);
  }

  modifier mintCompliance(uint256 numberOfTokens) {
    require(numberOfTokens > 0 && numberOfTokens <= maxMintAmountPerTx, "Invalid mint amount!");
    require(balanceOf(msg.sender) + numberOfTokens <= maxMintPerAddr, "Max token purchase exceeded!");
    require(totalSupply() + numberOfTokens <= maxSupply, "Max supply exceeded!");
    _;
  }

  modifier mintMaxSupply(uint256 numberOfTokens) {
    require(totalSupply() + numberOfTokens <= maxSupply, "Max supply exceeded!");
    _;
  }

  modifier mintMaxReserve(uint256 numberOfTokens) {
    require(balanceOf(msg.sender) + numberOfTokens <= maxReserve, "Max reserve exceeded!");
    _;
  }

  modifier mintPriceCompliance(uint256 numberOfTokens) {
    require(msg.value >= cost * numberOfTokens, "Insufficient funds!");
    _;
  }

  function whitelistMint(uint256 numberOfTokens, bytes32[] calldata _merkleProof) public payable mintCompliance(numberOfTokens) mintPriceCompliance(numberOfTokens) {
    // Verify whitelist requirements
    require(whitelistMintEnabled, "The whitelist sale is not enabled!");
    require(!whitelistClaimed[msg.sender], "Address already claimed!");
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid proof!");

    whitelistClaimed[msg.sender] = true;
    safeMint(msg.sender, numberOfTokens);
  }

  function mint(uint256 numberOfTokens) public payable mintCompliance(numberOfTokens) mintPriceCompliance(numberOfTokens) {
    require(!paused, "The contract is paused!");

    safeMint(msg.sender, numberOfTokens);
  }
  
  function gift(uint256 numberOfTokens, address _receiver) public mintMaxSupply(numberOfTokens) onlyOwner {
    safeMint(_receiver, numberOfTokens);
  }

  function reserveMint(uint256 numberOfTokens) public mintMaxReserve(numberOfTokens) onlyOwner {
    safeMint(msg.sender, numberOfTokens);
  }

  function _startTokenId() 
    internal
    view
    virtual
    override (ERC721A)
    returns (uint256) {
    return 1;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override (ERC721A)
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721AMetadata: URI query for nonexistent token"
    );

    if (revealed == false) {
      return bytes(hiddenMetadataUri).length > 0
        ? string(abi.encodePacked(hiddenMetadataUri, tokenId.toString(), uriSuffix))
        : "";
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), uriSuffix))
        : "";
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function setMaxSupply(uint256 _maxSupply) public onlyOwner {
    maxSupply = _maxSupply;
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setMaxMintPerAddr(uint256 _maxMintPerAddr) public onlyOwner {
    maxMintPerAddr = _maxMintPerAddr;
  }

  function setMaxReserve(uint256 _maxReserve) public onlyOwner {
    maxReserve = _maxReserve;
  }

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setWhitelistMintEnabled(bool _state) public onlyOwner {
    whitelistMintEnabled = _state;
  }

  function withdraw() public onlyOwner nonReentrant {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }

  function safeMint(address _receiver, uint256 numberOfTokens) internal {
        // Mint number of tokens requested
        _safeMint(_receiver, numberOfTokens);
  }

  function burn(uint256 tokenId) public onlyOwner {
    _burn(tokenId);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}
