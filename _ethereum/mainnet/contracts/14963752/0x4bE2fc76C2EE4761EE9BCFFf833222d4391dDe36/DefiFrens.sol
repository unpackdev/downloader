// SPDX-License-Identifier: MIT


//  ______   _______  _______  ___   _______  ______    _______  __    _  _______ 
// |      | |       ||       ||   | |       ||    _ |  |       ||  |  | ||       |
// |  _    ||    ___||    ___||   | |    ___||   | ||  |    ___||   |_| ||  _____|
// | | |   ||   |___ |   |___ |   | |   |___ |   |_||_ |   |___ |       || |_____ 
// | |_|   ||    ___||    ___||   | |    ___||    __  ||    ___||  _    ||_____  |
// |       ||   |___ |   |    |   | |   |    |   |  | ||   |___ | | |   | _____| |
// |______| |_______||___|    |___| |___|    |___|  |_||_______||_|  |__||_______|
// 

pragma solidity >=0.8.0 <0.9.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";

contract DefiFrens is ERC721A, Ownable, ReentrancyGuard {

  using Strings for uint256;

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;
 
  uint256 public maxSupply = 5555;
  uint256 public maxPublicMintAmountPerTx = 3;
  uint256 public maxWhitelist1MintAmountPerWallet = 1;
  uint256 public maxWhitelist2MintAmountPerWallet = 2;

  uint256 public publicMintCost = 0.077 ether;
  uint256 public whitelist1MintCost = 0.069 ether;
  uint256 public whitelist2MintCost = 0.069 ether;

  bytes32 public merkleRoot1;
  bytes32 public merkleRoot2;
  
  bool public paused = true;
  bool public whitelist1MintEnabled = false;
  bool public whitelist2MintEnabled = false;
  bool public revealed = false;

  constructor(
      string memory _tokenName, 
      string memory _tokenSymbol, 
      string memory _hiddenMetadataUri)  ERC721A(_tokenName, _tokenSymbol)  {
    hiddenMetadataUri = _hiddenMetadataUri;       
    ownerClaimed();
   
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _;
  }
  // ** RESERVE TOKENS FOR FUTURE COLLABS & STAFF ** //
  function ownerClaimed() internal {
    _mint(_msgSender(), 118);
  }

  //** FRENLIST MINT **//
  function whitelistMint1(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) {
    require(whitelist1MintEnabled, 'The Frenlist sale is not enabled!');
    require(_numberMinted(_msgSender()) + _mintAmount <= maxWhitelist1MintAmountPerWallet, 'Max limisted per wallet!');
    require(msg.value >= whitelist1MintCost * _mintAmount, 'Insufficient funds for Frenlist!');
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot1, leaf), 'Invalid proof for Frenlist!');

    _safeMint(_msgSender(), _mintAmount);
  }


  //** GOOD FRENS MINT **/
  function whitelistMint2(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) {
    require(whitelist2MintEnabled, 'The Goodfrens sale is not enabled!');
    require(_numberMinted(_msgSender()) + _mintAmount <= maxWhitelist2MintAmountPerWallet, 'Max limited per wallet!');
    require(msg.value >= whitelist2MintCost * _mintAmount, 'Insufficient funds for Good Frens!');
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot2, leaf), 'Invalid proof for Good Frens!');

    _safeMint(_msgSender(), _mintAmount);
  }

  //** Public Mint **/
  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) nonReentrant {
    require(!paused, 'The mint is paused!');
    require(msg.value >= publicMintCost * _mintAmount, 'Insufficient funds for public sale!');
    require(_mintAmount <= maxPublicMintAmountPerTx, 'Max limited per Transaction!');

    _safeMint(_msgSender(), _mintAmount);
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

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
    publicMintCost = _cost;
  }

  function setWhitelist1Cost(uint256 _cost) public onlyOwner {
    whitelist1MintCost = _cost;
  }

  function setWhitelist2Cost(uint256 _cost) public onlyOwner {
    whitelist2MintCost = _cost;
  }

  function setMaxPublicMintAmountPerTx(uint256 _maxPublicMintAmountPerTx) public onlyOwner {
    maxPublicMintAmountPerTx = _maxPublicMintAmountPerTx;
  }

  function setMaxWhitelist1MintAmountPerWallet(uint256 _maxWhitelist1MintAmountPerWallet) public onlyOwner {
    maxWhitelist1MintAmountPerWallet = _maxWhitelist1MintAmountPerWallet;
  }

  function setMaxWhitelist2MintAmountPerWallet(uint256 _maxWhitelist2MintAmountPerWallet) public onlyOwner {
    maxWhitelist2MintAmountPerWallet = _maxWhitelist2MintAmountPerWallet;
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

  function setMerkleRoot1(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot1 = _merkleRoot;
  }

  function setMerkleRoot2(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot2 = _merkleRoot;
  }

  function setWhitelist1MintEnabled(bool _state) public onlyOwner {
    whitelist1MintEnabled = _state;
  }

  function setWhitelist2MintEnabled(bool _state) public onlyOwner {
    whitelist2MintEnabled = _state;
  }

  function setMaxSupply(uint256 _maxSupply) public onlyOwner {
    maxSupply = _maxSupply;
  }
  
  function withdraw() public onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}
