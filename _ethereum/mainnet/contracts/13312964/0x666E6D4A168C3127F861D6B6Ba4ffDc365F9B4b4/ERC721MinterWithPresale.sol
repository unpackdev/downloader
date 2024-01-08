//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Strings.sol";

interface ERC721BaseLayer {
  function mintTo(address recipient, uint256 tokenId, string memory uri) external;
  function ownerOf(uint256 tokenId) external returns (address owner);
}

contract ERC721MinterWithPresale is Ownable {
  using Strings for *;

  address public erc721BaseContract;
  mapping(uint256 => uint256) public claimedTokens;
  uint256 public maxSupply;
  uint256 public reservedSupply;
  uint256 public price;
  uint256 public minted;
  uint256 public reserveMinted;
  uint256 public startId;
  uint256 public saleStartTime;
  uint256 public presaleStartTime;
  uint256 public buyLimit;
  uint256 public presaleBuyLimitPerQualifyingId;
  string public subCollectionURI;

  constructor(
    address erc721BaseContract_, 
    uint256 maxSupply_,
    uint256 reservedSupply_,
    uint256 price_,
    uint256 minted_, 
    uint256 startId_, 
    uint256 saleStartTime_,
    uint256 presaleStartTime_,
    uint256 buyLimit_,
    uint256 presaleBuyLimitPerQualifyingId_,
    string memory subCollectionURI_
  ) {
    erc721BaseContract = erc721BaseContract_;
    maxSupply = maxSupply_;
    reservedSupply = reservedSupply_;
    price = price_;
    minted = minted_;
    startId = startId_;
    saleStartTime = saleStartTime_;
    presaleStartTime = presaleStartTime_;
    buyLimit = buyLimit_;
    presaleBuyLimitPerQualifyingId = presaleBuyLimitPerQualifyingId_;
    subCollectionURI = subCollectionURI_;
  }

  function mintReserve(uint256 amount) public onlyOwner {
    require(minted + amount <= maxSupply, "Mint exceeds max supply limit");
    require(reserveMinted + amount <= reservedSupply, "Mint exceeds reserve supply limit");

    ERC721BaseLayer erc721 = ERC721BaseLayer(erc721BaseContract);

    uint256 tokenId = startId + minted;
    minted += amount;
    reserveMinted += amount;
    for(uint256 i; i < amount; i++) {
      erc721.mintTo(msg.sender, tokenId, string(abi.encodePacked(subCollectionURI, tokenId.toString(), '.json')));
      tokenId++;
    }
  }

  function mintPresale(uint256 amount, uint256 id) public payable {
    require(msg.value == amount * price, "Invalid payment amount");
    require(amount <= presaleBuyLimitPerQualifyingId, "Too many requested");
    require(minted + amount <= maxSupply - (reservedSupply - reserveMinted), "Purchase exceeds supply limit");
    require(block.timestamp >= presaleStartTime, "Presale has not started");
    require(id >= 1 && id <= 100, "Submitted tokenId does not qualify for presale");

    ERC721BaseLayer erc721 = ERC721BaseLayer(erc721BaseContract);
    address tokenOwner = erc721.ownerOf(id);

    require(msg.sender == tokenOwner, "Sender does not own the qualifying token");

    claimedTokens[id] += amount;
    require(claimedTokens[id] <= presaleBuyLimitPerQualifyingId, "Too many requested");

    uint256 tokenId = startId + minted; 
    minted += amount;
    for(uint256 i; i < amount; i++) {
        erc721.mintTo(msg.sender, tokenId, string(abi.encodePacked(subCollectionURI, tokenId.toString(), '.json')));
        tokenId++;
    }
  }

  function mint(uint256 amount) public payable {
    require(msg.value == amount * price, "Invalid payment amount");
    require(amount <= buyLimit, "Too many requested");
    require(minted + amount <= maxSupply - (reservedSupply - reserveMinted), "Purchase exceeds supply limit");
    require(msg.sender == tx.origin, "Purchase request must come directly from an EOA");
    require(block.timestamp >= saleStartTime, "Sale has not started");

    ERC721BaseLayer erc721 = ERC721BaseLayer(erc721BaseContract);

    uint256 tokenId = startId + minted;
    minted += amount;
    for(uint256 i; i < amount; i++) {
        erc721.mintTo(msg.sender, tokenId, string(abi.encodePacked(subCollectionURI, tokenId.toString(), '.json')));
        tokenId++;
    }
  }

  function withdraw() public onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
  }
}
