// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "./ERC721AQueryable.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";

/**                                                                 
 _   _  ___ _____   _ _   _ ____ _____ ____  _____ ____ _____ _   _ 
| \ | |/ _ |_   _| | | | | / ___|_   _|  _ \| ____/ ___| ____| \ | |
|  \| | | | || |_  | | | | \___ \ | | | | | |  _|| |  _|  _| |  \| |
| |\  | |_| || | |_| | |_| |___) || | | |_| | |__| |_| | |___| |\  |
|_| \_|\___/ |_|\___/ \___/|____/ |_| |____/|_____\____|_____|_| \_|
                                                                                                                                                                                                                 
*/

contract NotJustDegen is ERC721A, Ownable, ReentrancyGuard {

  using Strings for uint256;

  bytes32 public merkleRoot;
  mapping(address => bool) public whitelistMintClaimed;

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;
  
  uint256 public cost;
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;
  
  bool public publicMintEnabled = false;
  bool public whitelistMintEnabled = false;
  bool public revealed = false;
  

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    string memory _hiddenMetadataUri,
    uint256 _cost,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerTx
  ) ERC721A(_tokenName, _tokenSymbol){
    setCost(_cost);
    maxSupply = _maxSupply;
    setMaxMintAmountPerTx(_maxMintAmountPerTx);
    setHiddenMetadataUri(_hiddenMetadataUri);
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount!");
    require(totalSupply() + _mintAmount <= maxSupply, "Max supply exceeded!");
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= cost * _mintAmount, "Insufficient funds!");
    _;
  }

  modifier whitelistMintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= cost * (_mintAmount - 1), "Insufficient funds!");
    _;
  }

  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) whitelistMintPriceCompliance(_mintAmount) {
    // Verify whitelistmint requirements
    require(whitelistMintEnabled, "The whitelist mint is not enabled!");
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid proof!");
    require(!whitelistMintClaimed[_msgSender()], "Address already claimed!");
    
    whitelistMintClaimed[_msgSender()] = true;
    _safeMint(_msgSender(), _mintAmount);
  }

 function internalMint(uint256 _teamAmount) external onlyOwner  {
    require(totalSupply() + _teamAmount <= maxSupply, "Max supply exceeded!");
    _safeMint(_msgSender(), _teamAmount);
  }

  function publicMint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(publicMintEnabled, "The public sale is not enabled!");

    _safeMint(_msgSender(), _mintAmount);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public onlyOwner {
    require(totalSupply() + _mintAmount <= maxSupply, "Max supply exceeded!");
    _safeMint(_receiver, _mintAmount);
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory){
    require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
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

  function setPublicMintEnabled(bool _state) public onlyOwner {
    publicMintEnabled = _state;
  }

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setWhitelistMintEnabled(bool _state) public onlyOwner {
    whitelistMintEnabled = _state;
  }

  function withdraw() public onlyOwner nonReentrant {
      uint256 balance = address(this).balance;
      payable(msg.sender).transfer(balance);
    }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}


