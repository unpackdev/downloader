// SPDX-License-Identifier: MIT
/// @title Futurists Contract

pragma solidity ^0.8.9;

import "./ERC721A.sol";
import "./IERC2981.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";

contract Futurists is 
     ERC721A, 
     IERC2981,
     Ownable, 
     ReentrancyGuard 
{
  using Strings for uint256;

  bytes32 public merkleRoot;

  address public royaltyAddress;

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenUri = '';

  uint256 public maxSupply = 333;
  uint256 public royalty = 100; // Must be a whole number 3.3% is 33
  uint256 public price = 0.059 ether;

  bool public paused = true;
  bool public revealed = false;
  bool public whitelist = false;

  mapping(address => bool) public addressClaimed; 

  constructor() 
  ERC721A("Futurists", "FUTU") {
    royaltyAddress = msg.sender;
  }

/// @dev === MODIFIER ===
  modifier mintCompliance() {
    require(totalSupply() + 1 <= maxSupply, 'Sold out!');
    require(!addressClaimed[_msgSender()], 'Address already claimed!');
    require(msg.value >= price, 'Insufficient funds!');
    _;
  }

/// @dev === Minting Function - Input ====

  ///Whitelist
  function whitelistMint(bytes32[] calldata _merkleProof) public payable
  mintCompliance() 
  nonReentrant
  {
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid signature!');
    require(whitelist, 'The whitelist sale is not enabled!');
    addressClaimed[_msgSender()] = true;
    _safeMint(_msgSender(), 1);
  }

  ///Public
  function publicMint() public payable
  mintCompliance() 
  nonReentrant
  {
    require(!paused, 'The contract is paused!');

    addressClaimed[_msgSender()] = true;
    _safeMint(_msgSender(), 1);
  }

  ///Reserve Function
  function mintForAddress(uint256 _amount, address _receiver) public onlyOwner {
    require(totalSupply() + _amount <= maxSupply, 'Sold out!');

    _safeMint(_receiver, _amount);
  }

/// @dev === Override ERC721A ===
  function _startTokenId() internal view virtual override returns (uint256) {
      return 1;
    }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'Nonexistent token!');

    if (revealed == false) {
      return hiddenUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }

/// @dev === Owner Control/Configuration Functions ===
  function pause() public onlyOwner {
    paused = !paused;
  }

  function flipWhitelist() public onlyOwner {
    whitelist = !whitelist;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setHiddenUri(string memory _uriHidden) public onlyOwner {
    hiddenUri = _uriHidden;
  }

  function reveal() public onlyOwner {
    revealed = true;
  }

  function setRoyaltyAddress(address _royaltyAddress) public onlyOwner {
    royaltyAddress = _royaltyAddress;
  }

  function setRoyaly(uint256 _royalty) external onlyOwner {
        royalty = _royalty;
  }

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

/// @dev === INTERNAL READ-ONLY ===
  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }

/// @dev === Withdraw ====
  function withdraw() public onlyOwner nonReentrant {
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }

//IERC2981 Royalty Standard
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external view override returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(tokenId), "Nonexistent token");
        return (royaltyAddress, (salePrice * royalty) / 1000);
    }                                                

/// @dev === Support Functions ==
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, IERC165) returns (bool) {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}