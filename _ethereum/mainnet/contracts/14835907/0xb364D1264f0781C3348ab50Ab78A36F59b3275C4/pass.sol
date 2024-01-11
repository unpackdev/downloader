// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";

contract PASS is Ownable, ERC721A, ReentrancyGuard {
  string private _defaultTokenURI;

  uint256 public collectionSize;
  uint256 public maxBatchSize;

  struct WhitelistSaleConfig {
    bytes32 merkleRoot;
    uint32 startTime;
    uint32 endTime;
    uint64 price;
    uint64 maxPerAddress;
  }

  WhitelistSaleConfig public whitelistSaleConfig;

  constructor(
    uint256 collectionSize_,
    uint256 maxBatchSize_
  ) ERC721A("WAGMI Team Pass", "WGMTMPSS") {
    collectionSize = collectionSize_;
    maxBatchSize = maxBatchSize_;
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

  function setDefaultTokenURI(string calldata uri) external onlyOwner {
    _defaultTokenURI = uri;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721A)
    returns (string memory)
  {
    require(tokenId <= totalSupply(), "token not exist");
    return _defaultTokenURI;
  }

  function refundIfOver(uint256 price) private {
    require(msg.value >= price, "need to send more ETH");
    if (msg.value > price) {
      payable(msg.sender).transfer(msg.value - price);
    }
  }

  function setCollectionSize(uint256 size) external onlyOwner {
    collectionSize = size;
  }

  function setupWhitelistSale(
    bytes32 merkleRoot,
    uint32 whitelistSaleStartTime,
    uint32 whitelistSaleEndTime,
    uint64 whitelistSalePriceWei,
    uint64 maxPerAddressDuringWhitelistSaleMint
  ) external onlyOwner {
    whitelistSaleConfig.merkleRoot = merkleRoot;
    whitelistSaleConfig.startTime = whitelistSaleStartTime;
    whitelistSaleConfig.endTime = whitelistSaleEndTime;
    whitelistSaleConfig.price = whitelistSalePriceWei;
    whitelistSaleConfig.maxPerAddress = maxPerAddressDuringWhitelistSaleMint;
  }

  function setMerkleRoot(bytes32 root) external onlyOwner {
    whitelistSaleConfig.merkleRoot = root;
  }

  function whitelistSaleMint(bytes32[] calldata proof, uint64 quantity)
    external
    payable
    callerIsUser
    nonReentrant
  {
    uint256 price = uint256(whitelistSaleConfig.price);
    uint256 saleStartTime = uint256(whitelistSaleConfig.startTime);
    uint256 saleEndTime = uint256(whitelistSaleConfig.endTime);
    uint64 maxPerAddress = whitelistSaleConfig.maxPerAddress;
    require(
      saleStartTime != 0
      && block.timestamp >= saleStartTime && block.timestamp <= saleEndTime,
      "whitelist sale has not begun yet"
    );
    require(totalSupply() + quantity <= collectionSize, "reached max supply");
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(
      MerkleProof.verify(proof, whitelistSaleConfig.merkleRoot, leaf),
      "invalid whitelist proof"
    );
    require(
      numberMinted(msg.sender) + quantity <= maxPerAddress,
      "can not mint this many"
    );

    _safeMint(msg.sender, quantity);
    refundIfOver(price * quantity);
  }

  function devMint(uint256 quantity) external onlyOwner {
    require(totalSupply() + quantity <= collectionSize, "reached max supply");
    require(
      quantity % maxBatchSize == 0,
      "can only mint a multiple of the maxBatchSize"
    );
    uint256 numChunks = quantity / maxBatchSize;
    for(uint256 i = 0; i < numChunks; i++) {
      _safeMint(msg.sender, maxBatchSize);
    }
  }

  function withdrawMoney() external onlyOwner nonReentrant {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "transfer failed");
  }

  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }
}
