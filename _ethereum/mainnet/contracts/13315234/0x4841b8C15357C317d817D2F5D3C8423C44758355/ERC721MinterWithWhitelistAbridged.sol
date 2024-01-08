//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./Strings.sol";

interface ERC721BaseLayer {
  function mintTo(address recipient, uint256 tokenId, string memory uri) external;
  function ownerOf(uint256 tokenId) external returns (address owner);
}

contract ERC721MinterWithWhitelist is Ownable {
  using Strings for *;

  address public erc721BaseContract;
  mapping(address => uint256) public whiteList;
  uint256 public maxSupply;
  uint256 public reservedSupply;
  uint256 public price;
  uint256 public minted;
  uint256 public reserveMinted;
  uint256 public startId;
  string public subCollectionURI;

  constructor(
    address erc721BaseContract_, 
    uint256 maxSupply_,
    uint256 reservedSupply_,
    uint256 price_,
    uint256 minted_, 
    uint256 startId_, 
    string memory subCollectionURI_
  ) {
    erc721BaseContract = erc721BaseContract_;
    maxSupply = maxSupply_;
    reservedSupply = reservedSupply_;
    price = price_;
    minted = minted_;
    startId = startId_;
    subCollectionURI = subCollectionURI_;
    whiteList[address(0xc55Ea01bFF091198CdA9d91100500b70c532b1A5)] = 2;
    whiteList[address(0x9eE5E3Ff06425CF972E77c195F70Ecb18aC23d7f)] = 5;
    whiteList[address(0xa68C1331bC465cfa7FB60bBdd17F4Bb57510F9f4)] = 2;
    whiteList[address(0x062F70147e58CeBa9220B6Aa0084135c21dAACee)] = 2;
    whiteList[address(0x2123EDD3Ed0f0c09A7AF4Cab58B4881B50A1F878)] = 2;
    whiteList[address(0xDd762af79fBBc73b51941Fdd1Fef8e89101EB51B)] = 2;
    whiteList[address(0xb905576A1D9Bff3b7F3A69764913037ea18F01dA)] = 2;
    whiteList[address(0x5d7d6f679083f3ebFC6A510C418b4E1B2f754FAe)] = 2;
    whiteList[address(0x7c7d093b4Fb96C89fcC29cD4c24c15DB0ed669dF)] = 2;
    whiteList[address(0x3665e13eC88D60a490eb8B34aCab4A52D46EC8c2)] = 1;
    whiteList[address(0xD1edDfcc4596CC8bD0bd7495beaB9B979fc50336)] = 2;
    whiteList[address(0x7B406Fa711451dE9E34D8Bb76c7c2D786e92047a)] = 1;
    whiteList[address(0xc86D5e4b89a0d9D4978444C9aB282C2D41918eEa)] = 2;
    whiteList[address(0x4cF93693586FE5E2F2c7097140F2EfA23e3e3FBa)] = 1;
    whiteList[address(0x148e2ED011A9EAAa200795F62889D68153EEacdE)] = 2;
  }

  function updateWhitelist(address[] memory registrants, uint256[] memory amount) public onlyOwner {
      for(uint256 i; i < registrants.length; i++) {
          whiteList[registrants[i]] = amount[i];
      }
  }

  function mintWhitelist(uint256 amount) public payable {
    require(msg.value == amount * price, "Invalid payment amount");
    require(reserveMinted + amount <= reservedSupply, "Purchase exceeds reserve supply limit");
    require(amount <= whiteList[msg.sender], "Sender not whitelisted or amount exceeds reservation");
    whiteList[msg.sender] -= amount;

    ERC721BaseLayer erc721 = ERC721BaseLayer(erc721BaseContract);

    uint256 tokenId = startId + minted; 
    minted += amount;
    reserveMinted += amount;
    for(uint256 i; i < amount; i++) {
        erc721.mintTo(msg.sender, tokenId, string(abi.encodePacked(subCollectionURI, tokenId.toString(), '.json')));
        tokenId++;
    }
  }

  function withdraw() public onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
  }
}
