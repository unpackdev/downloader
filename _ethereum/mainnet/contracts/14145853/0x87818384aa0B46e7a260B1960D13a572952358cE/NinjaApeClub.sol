// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./Strings.sol";

contract NinjaApeHideout is Ownable, ERC721A, ReentrancyGuard {
  uint256 public immutable maxPerAddressDuringMint;
  uint256 public immutable amountForDevs;
  uint256 public cost = 0.04 ether;
  uint256 public freeSupply = 666;
  uint256 public maxMintAmountPerTx = 10;
  uint256 public maxMintAmountPerTxFree = 2;
  bool public paused = true;

  constructor(
    uint256 maxBatchSize_,
    uint256 collectionSize_,
    uint256 amountForDevs_
  ) ERC721A("NinjaApeHideout", "NAH", maxBatchSize_, collectionSize_) {
    maxPerAddressDuringMint = maxBatchSize_;
    amountForDevs = amountForDevs_;
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "E01");
    _;
  }

  function publicSaleMint(uint256 quantity) external payable callerIsUser {
    require(!paused, "E04");
    require(totalSupply() + quantity <= collectionSize, "E05");
    require(numberMinted(msg.sender) + quantity <= maxPerAddressDuringMint);
    if (totalSupply() >= freeSupply) {
        require(quantity > 0 && quantity <= maxMintAmountPerTx, "E02");
        require(msg.value >= cost * quantity, "E06");
    } else {
        require(quantity > 0 && quantity <= maxMintAmountPerTxFree, "E0");
    }
    _safeMint(msg.sender, quantity);
  }

  function setFreeSupply(uint256 _freeSupply) external onlyOwner {
    freeSupply = _freeSupply;
  }

  function setCost(uint256 _cost) external onlyOwner {
    cost = _cost;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  // For marketing etc.
  function devMint(uint256 quantity) external onlyOwner {
    require(
      totalSupply() + quantity <= amountForDevs,
      "E09"
    );
    require(
      quantity % maxBatchSize == 0,
      "E10"
    );
    uint256 numChunks = quantity / maxBatchSize;
    for (uint256 i = 0; i < numChunks; i++) {
      _safeMint(msg.sender, maxBatchSize);
    }
  }

  // // metadata URI
  string private _baseTokenURI;

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  function withdrawBalance() external onlyOwner nonReentrant {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "E11");
  }

  function setOwnersExplicit(uint256 quantity) external onlyOwner nonReentrant {
    _setOwnersExplicit(quantity);
  }

  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  function getOwnershipData(uint256 tokenId)
    external
    view
    returns (TokenOwnership memory)
  {
    return ownershipOf(tokenId);
  }
}
