// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./RandomlyAssigned.sol";

contract DogeClub is ERC721Enumerable, Ownable, RandomlyAssigned { 
  using Strings for uint256;
  
  uint256 public currentSupply = 0;
  uint256 public cost = 40000000 gwei; 
  uint256 public maxSupply = 1000; // Needs to be 10,000 on mainnet
  uint256 public maxMintAmount = 20; 
  string public baseURI;  
  bool public paused = true; 

  constructor()
    public ERC721("DOGE CLUB", "DC") 
    RandomlyAssigned(maxSupply,1) {}
    
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

  function mint(uint256 _mintAmount) public payable {
    require(!paused, "Paused Contract");
    require(_mintAmount > 0, "Need an amount");
    require(_mintAmount <= maxMintAmount, "To many");
    require(currentSupply + _mintAmount <= maxSupply, "Not enough left");
    
    if (msg.sender != owner()) {
      require(msg.value >= cost * _mintAmount, "Bad maths");
    }

    for (uint256 i = 1; i <= _mintAmount; i++) {
        uint256 id = nextToken();
        _safeMint(msg.sender, id);
        currentSupply++;
    }
  }

  // Token URI overrided 
  function tokenURI(uint256 tokenId) public view override virtual returns (string memory) {
    bytes32 tokenIdBytes;
    if (tokenId == 0) {
      tokenIdBytes = "0";
    } else {
      uint256 value = tokenId;
      while (value > 0) {
        tokenIdBytes = bytes32(uint256(tokenIdBytes) / (2 ** 8));
        tokenIdBytes |= bytes32(((value % 10) + 48) * 2 ** (8 * 31));
        value /= 10;
      }
    }

    bytes memory prefixBytes = bytes(baseURI);
    bytes memory tokenURIBytes = new bytes(prefixBytes.length + tokenIdBytes.length);

    uint8 i;
    uint8 index = 0;
        
    for (i = 0; i < prefixBytes.length; i++) {
      tokenURIBytes[index] = prefixBytes[i];
      index++;
    }
        
    for (i = 0; i < tokenIdBytes.length; i++) {
      tokenURIBytes[index] = tokenIdBytes[i];
      index++;
    }
        
    return string(tokenURIBytes);
  }

 function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }

  function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
    require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
    
    return _allTokens[index];
  }

  function tokensOfOwner(address _owner) external view returns(uint256[] memory) {
    uint tokenCount = balanceOf(_owner);
    uint256[] memory tokenId = new uint256[](tokenCount);
    
    for(uint i = 0; i < tokenCount; i++){
      tokenId[i] = tokenOfOwnerByIndex(_owner, i);
    }
    
    return tokenId;
  }

  //only owner
  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI; 
  }

  function pause(bool _state) public onlyOwner {
    require(keccak256(abi.encodePacked(baseURI)) != keccak256(abi.encodePacked("")), "No baseURI set");
    paused = _state;
  }

  function withdraw() public payable onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }

}