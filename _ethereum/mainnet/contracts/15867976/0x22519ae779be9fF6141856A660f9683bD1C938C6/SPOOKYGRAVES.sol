// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";

contract SpookyGraves is ERC721A, Ownable, ReentrancyGuard {
  //using Strings for uint256;
  
  uint256 public GRAVES_SUPPLY = 4444;
  uint256 public GRAVES_FREE_SUPPLY = 500;
  uint256 public GRAVES_PUBLIC_PRICE = 0.007 ether;
  uint256 public GRAVES_WHITELIST_PRICE = 0.005 ether;
  uint256 public MAX_GRAVES_PER_TX = 3;
  
  bool public MintEnabled = false;

  bytes32 public merkleRoot;
  mapping(address => bool) public whitelistClaimed;
  mapping(address => bool) public publicClaimed;
  string public uriSuffix = ".json";
  string public baseURI = "";
  bool private whitelist = true;
  
  
  constructor(
    string memory _tokenName,
    string memory _tokenSymbol
  ) ERC721A(_tokenName, _tokenSymbol) {
  }

  function MintWhitelist(uint256 _gravesAmount, bytes32[] memory _proof) public payable{
    uint256 mintedGraves = totalSupply();
    require(MintEnabled, "The graves aren't open yet");
    require(_gravesAmount <= MAX_GRAVES_PER_TX, "Invalid graves amount");
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(MerkleProof.verify(_proof, merkleRoot, leaf) || whitelist, "Invalid proof!");
    if (mintedGraves + _gravesAmount > GRAVES_FREE_SUPPLY){
       require(msg.value >= _gravesAmount * GRAVES_WHITELIST_PRICE, "Eth Amount Invalid");
    }
    _mint(msg.sender, _gravesAmount);
    delete mintedGraves;
  }

  function MintPublic(uint256 _gravesAmount) public payable{
    uint256 mintedGraves = totalSupply();
    require(MintEnabled, "The graves aren't open yet");
    require(_gravesAmount <= MAX_GRAVES_PER_TX, "Invalid graves amount");
    if (mintedGraves + _gravesAmount > GRAVES_FREE_SUPPLY){
       require(msg.value >= _gravesAmount * GRAVES_PUBLIC_PRICE, "Eth Amount Invalid");
    }
    _mint(msg.sender, _gravesAmount);
    delete mintedGraves;
  }


 function adminMint(uint256 _teamAmount) external onlyOwner{
    _mint(msg.sender, _teamAmount);
  }


  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setMintEnabled(bool _state) public onlyOwner {
    MintEnabled = _state;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
  }


 function isValid(bytes32[] memory proof) public view returns (bool) {
      bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
      return MerkleProof.verify(proof, merkleRoot, leaf);
  }


  function withdrawBalance() external onlyOwner {
      (bool success, ) = msg.sender.call{value: address(this).balance}("");
      require(success, "WITHDRAW FAILED!");
    }

}