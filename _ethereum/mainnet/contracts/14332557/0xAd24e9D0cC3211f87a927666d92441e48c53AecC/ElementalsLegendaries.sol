// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ERC721A.sol";
import "./ERC721Enumerable.sol";
import "./MerkleProof.sol";
import "./Ownable.sol";

interface IElementals {
  function ownerOf(uint256 tokenId) external returns (address);
}

contract ElementalsLegendaries is Ownable, ERC721A {
  uint256 public supply = 500;
  uint256 public elementLimit = 100;
  uint256 public claimLimit = 1;
  bool public claimOn = false;
  string public baseUrl;
  mapping(uint256 => bool) public claimed;
  mapping(address => bool) public mintedEarth;
  mapping(address => bool) public mintedWater;
  mapping(address => bool) public mintedFire;
  mapping(address => bool) public mintedWind;
  mapping(address => bool) public mintedLightning;
  mapping(uint256 => uint256) public tokenIdElements;
  uint256 public earthTokensMinted = 0;
  uint256 public waterTokensMinted = 0;
  uint256 public fireTokensMinted = 0;
  uint256 public windTokensMinted = 0;
  uint256 public lightningTokensMinted = 0;
  bytes32 public earthMerkleRoot = 0x8d407346dd7f49bd77c811f92e379e32a6567bddccc3b67c1fa17d31d5951d1b;
  bytes32 public waterMerkleRoot = 0xf6306bb2c9295fc820662c96dd358e45b20edacdbd48b674fda2bb12858582fd;
  bytes32 public fireMerkleRoot = 0x5cbbb0e7e8c5a272266a15cb3fb63049f08363e2ecada8d7a166fa9ba2fbcd3c;
  bytes32 public windMerkleRoot = 0x88fb317bf027115c8311d35c41fbfb3e9342472773062d3122ecdf0bf77b63b5;
  bytes32 public lightningMerkleRoot = 0xd0b011c4f8bca0c4e9dcd541d64a7a8da05903f8c106de45bde12fe28a35bb66;

  IElementals elementals;

  constructor(string memory _baseUrl, address _elementals) ERC721A("ElementalsLegendaries", "LEGENDARY", claimLimit, supply) {
    baseUrl = _baseUrl;
    elementals = IElementals(_elementals);
  }

  /// @notice Claim earth legendary
  /// @param proofs list of token proofs
  /// @param tokenIds list of tokens to claim with
  function claimEarthLegendary(bytes32[][] calldata proofs, uint256[] memory tokenIds) 
  external canClaim(proofs, tokenIds, earthTokensMinted, mintedEarth) isVerified(proofs, tokenIds, earthMerkleRoot) {
    uint256 currentTokenId = totalSupply();
    _safeMint(msg.sender, 1);
    earthTokensMinted++;
    mintedEarth[msg.sender] = true;
    tokenIdElements[currentTokenId] = 1;
    delete currentTokenId;
  }

  /// @notice Claim water legendary
  /// @param proofs list of token proofs
  /// @param tokenIds list of tokens to claim with
  function claimWaterLegendary(bytes32[][] calldata proofs, uint256[] memory tokenIds)
  external canClaim(proofs, tokenIds, waterTokensMinted, mintedWater) isVerified(proofs, tokenIds, waterMerkleRoot) {
    uint256 currentTokenId = totalSupply();
    _safeMint(msg.sender, 1);
    waterTokensMinted++;
    mintedWater[msg.sender] = true;
    tokenIdElements[currentTokenId] = 2;
    delete currentTokenId;
  }

  /// @notice Claim fire legendary
  /// @param proofs list of token proofs
  /// @param tokenIds list of tokens to claim with
  function claimFireLegendary(bytes32[][] calldata proofs, uint256[] memory tokenIds)
  external canClaim(proofs, tokenIds, fireTokensMinted, mintedFire) isVerified(proofs, tokenIds, fireMerkleRoot) {
    uint256 currentTokenId = totalSupply();
    _safeMint(msg.sender, 1);
    fireTokensMinted++;
    mintedFire[msg.sender] = true;
    tokenIdElements[currentTokenId] = 3;
    delete currentTokenId;
  }

  /// @notice Claim wind legendary
  /// @param proofs list of token proofs
  /// @param tokenIds list of tokens to claim with
  function claimWindLegendary(bytes32[][] calldata proofs, uint256[] memory tokenIds)
  external canClaim(proofs, tokenIds, windTokensMinted, mintedWind) isVerified(proofs, tokenIds, windMerkleRoot) {
    uint256 currentTokenId = totalSupply();
    _safeMint(msg.sender, 1);
    windTokensMinted++;
    mintedWind[msg.sender] = true;
    tokenIdElements[currentTokenId] = 4;
    delete currentTokenId;
  }

  /// @notice Claim lightning legendary
  /// @param proofs list of token proofs
  /// @param tokenIds list of tokens to claim with
  function claimLightningLegendary(bytes32[][] calldata proofs, uint256[] memory tokenIds)
  external canClaim(proofs, tokenIds, lightningTokensMinted, mintedLightning) isVerified(proofs, tokenIds, lightningMerkleRoot) {
    uint256 currentTokenId = totalSupply();
    _safeMint(msg.sender, 1);
    lightningTokensMinted++;
    mintedLightning[msg.sender] = true;
    tokenIdElements[currentTokenId] = 5;
    delete currentTokenId;
  }

  modifier canClaim(bytes32[][] calldata proofs, uint256[] memory tokenIds, uint256 tokenId, mapping(address => bool) storage minted) {
    require(claimOn, "Legendary claiming paused");
    require(!minted[msg.sender], "Account owns legendary");
    require(tokenIds.length == 10, "10 elementals needed to claim a legendary");
    require(tokenId < elementLimit, "Legendary sold out");
    require(proofs.length == tokenIds.length, "Invalid number of proofs");
    _;
  }

  modifier isVerified(bytes32[][] calldata proofs, uint256[] memory tokenIds, bytes32 merkleRoot) {
    for (uint256 i; i < tokenIds.length; i++) {
      uint256 tokenId = tokenIds[i];
      bytes32[] memory proof = proofs[i];
      require(elementals.ownerOf(tokenId) == msg.sender, "Not elemental owner");
      require(!claimed[tokenId], "Elemental used for claiming");
      require(verifyElement(tokenId, proof, merkleRoot), "Invalid proof");
      claimed[tokenId] = true;
      delete tokenId;
      delete proof;
    }
    _;
  }
  
  /// @notice verify merkle proof
  /// @param tokenId elemental token id
  /// @param proof token proof
  /// @param root merkle tree root
  function verifyElement(uint256 tokenId, bytes32[] memory proof, bytes32 root) pure internal returns (bool) {
    bytes32 leaf = keccak256(abi.encodePacked(tokenId));
    return MerkleProof.verify(proof, root, leaf);
  }

  /// @notice Set base url
  /// @param _baseUrl new base url
  function setBaseUrl(string memory _baseUrl) external onlyOwner {
    baseUrl = _baseUrl;
  }

  /// @notice Set claim on
  /// @param _claimOn boolean to turn claiming on or off
  function setClaimOn(bool _claimOn) external onlyOwner {
    claimOn = _claimOn;
  }

  /// @notice Set Elementals contract address
  /// @param _elementals elementals smart contract address
  function setElementalsContract(address _elementals) external onlyOwner {
    elementals = IElementals(_elementals);
  }

  /// @notice Retrieves token URI metadata 
  /// @param tokenId token id of NFT to retrieve metadata
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    if (bytes(baseUrl).length <= 0) return "";
    uint256 element = tokenIdElements[tokenId];
    if (element == 1) {
      return string(abi.encodePacked(baseUrl, "1"));
    } else if (element == 2) {
      return string(abi.encodePacked(baseUrl, "2"));
    } else if (element == 3) {
      return string(abi.encodePacked(baseUrl, "3"));
    } else if (element == 4) {
      return string(abi.encodePacked(baseUrl, "4"));
    } else if (element == 5) {
      return string(abi.encodePacked(baseUrl, "5"));
    } else {
      return "";
    }
  }
}