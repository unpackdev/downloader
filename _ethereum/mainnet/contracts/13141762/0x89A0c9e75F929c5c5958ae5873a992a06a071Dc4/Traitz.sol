// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721.sol";
import "./ERC721Burnable.sol";
import "./ERC721Enumerable.sol";

// ███    ███ ███████ ████████  █████  ███████ ██   ██ ██ █████████ ███████
// ████  ████ ██         ██    ██   ██ ██      ██  ██  ██ ██     ██    ███
// ██ ████ ██ █████      ██    ███████ ███████ █████   ██ ██     ██   ███
// ██  ██  ██ ██         ██    ██   ██      ██ ██  ██  ██ ██     ██  ███
// ██      ██ ███████    ██    ██   ██ ███████ ██   ██ ██ ██     ██ ███████
// 🥯 bagelface
// 🐦 @bagelface_
// 🎮 bagelface#2027
// 📬 bagelface@protonmail.com

contract Traitz is ERC721, ERC721Burnable, ERC721Enumerable, Ownable {
  using Address for address;

  uint256 public EDITION = 0;
  uint256 public MAX_SUPPLY = 120_000;
  string public METADATA_PROVENANCE;
  string public SEED_PROVENANCE;

  uint256 private _tokenIds;
  string private _baseTokenURI;
  string private _contractURI;
  string private _metadataURI;
  bytes32 private _privateSeed;
  mapping(uint256 => bytes32) private _publicSeeds;

  constructor(
    string memory baseTokenURI,
    string memory metadataProvenance,
    string memory seedProvenance
  )
    ERC721("metaSKINZ Traitz", "TRAITZ")
  {
    _baseTokenURI = baseTokenURI;
    METADATA_PROVENANCE = metadataProvenance;
    SEED_PROVENANCE = seedProvenance;
  }

  function tokenIds() public view returns (uint256) {
    return _tokenIds;
  }

  function metadataURI() public view returns (string memory) {
    return _metadataURI;
  }

  function contractURI() public view returns (string memory) {
    return _contractURI;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setMetadataURI(string memory URI) public onlyOwner {
    _metadataURI = URI;
  }

  function setContractURI(string memory URI) public onlyOwner {
    _contractURI = URI;
  }

  function setBaseTokenURI(string memory URI) public onlyOwner {
    _baseTokenURI = URI;
  }

  function privateSeed() public view returns (bytes32) {
    require(_privateSeed != bytes32(0), "Private seed has not been revealed");

    return _privateSeed;
  }

  function setPrivateSeed(bytes32 seed) public onlyOwner {
    require(_privateSeed == bytes32(0), "Private seed has already been set");

    _privateSeed = seed;
  }

  function publicSeed(uint256 tokenId) public view returns (bytes32) {
    require(_exists(tokenId), "Token does not exist");

    return _publicSeeds[tokenId];
  }

  function _setPublicSeed(uint256 tokenId, address to) private {
    _publicSeeds[tokenId] = keccak256(abi.encodePacked(tokenId, block.difficulty, block.timestamp, to));
  }

  function trait(uint256 tokenId) public view returns (bytes32) {
    require(_exists(tokenId), "Token does not exist");

    return keccak256(abi.encode(publicSeed(tokenId), privateSeed()));
  }

  function mint(uint256 amount, address to) public onlyOwner {
    require(_tokenIds + amount < MAX_SUPPLY, "Exceeds maximum number of tokens");

    for (uint256 i = 0; i < amount; i++) {
      _safeMint(to, _tokenIds);
      _setPublicSeed(_tokenIds, to);
      _tokenIds += 1;
    }
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
    return super.supportsInterface(interfaceId);
  }
}