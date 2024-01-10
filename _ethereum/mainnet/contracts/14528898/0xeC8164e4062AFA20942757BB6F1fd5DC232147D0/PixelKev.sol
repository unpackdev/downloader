// SPDX-License-Identifier: MIT
// Creator: RobotChicken

pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./Hash.sol";

contract PixelKev is ERC721A, Ownable {
  using Strings for uint256;
  using Hash for bytes32;

  uint256 public mintStartTime;
  uint256 public maxBatchSize;
  uint256 public immutable collectionSize;
  string private _baseTokenURI;
  string private _uriSecret;

  constructor(
    string memory baseTokenURI_,
    uint256 maxBatchSize_,
    uint256 collectionSize_,
    uint256 mintStartTime_
  )
    ERC721A("PixelKev", "KEV")
    Ownable()
  {
    require(collectionSize_ > 0, "ERC721A: collection size must be nonzero");
    require(maxBatchSize_ > 0, "ERC721A: max batch size must be nonzero");

    _baseTokenURI = baseTokenURI_;
    maxBatchSize = maxBatchSize_;
    collectionSize = collectionSize_;
    mintStartTime = mintStartTime_;
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

    string memory baseURI = _baseURI();
    bytes32 filename = keccak256(abi.encodePacked(tokenId.toString(), _uriSecret));
    string memory path = string(abi.encodePacked("/", filename.toHex()));
    return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, path)) : '';
  }

  function _baseURI() override view internal returns (string memory) {
    return _baseTokenURI;
  }

  function mint(uint256 quantity) external {
    require(
      mintStartTime != 0 && block.timestamp >= mintStartTime,
      "Mint has not started yet"
    );
    require(quantity <= maxBatchSize, "ERC721A: quantity to mint too high");
    require(
      totalSupply() + quantity <= collectionSize,
      "ERC721A: limit reached"
      );

    _safeMint(msg.sender, quantity);
  }

  function setMintStartTime(uint256 mintStartTime_) external onlyOwner {
    mintStartTime = mintStartTime_;
  }

  function setMaxBatchSize(uint256 batchSize) external onlyOwner {
    maxBatchSize = batchSize;
  }

  function setBaseTokenURI(string memory baseTokenURI_) external onlyOwner {
    _baseTokenURI = baseTokenURI_;
  }

  function uriSecret() external view onlyOwner returns (string memory) {
    return _uriSecret;
  }

  function setUriSecret(string memory uriSecret_) external onlyOwner {
    _uriSecret = uriSecret_;
  }
}
