//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Strings.sol";

interface ERC721BaseLayer {
  function mintTo(address recipient, uint256 tokenId, string memory uri) external;
}

contract ERC721Minter is Ownable {
  using Strings for *;

  address public erc721BaseContract;
  uint256 public maxSupply;
  uint256 public reservedSupply;
  uint256 public price;
  uint256 public minted;
  uint256 public reserveMinted;
  uint256 public startId;
  uint256 public saleStartTime;
  uint256 public buyLimit;
  string public subCollectionURI;

  constructor(
    address erc721BaseContract_, 
    uint256 maxSupply_,
    uint256 reservedSupply_,
    uint256 price_,
    uint256 minted_, 
    uint256 startId_, 
    uint256 saleStartTime_, 
    uint256 buyLimit_,
    string memory subCollectionURI_
  ) {
    erc721BaseContract = erc721BaseContract_;
    maxSupply = maxSupply_;
    reservedSupply = reservedSupply_;
    price = price_;
    minted = minted_;
    startId = startId_;
    saleStartTime = saleStartTime_;
    buyLimit = buyLimit_;
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
