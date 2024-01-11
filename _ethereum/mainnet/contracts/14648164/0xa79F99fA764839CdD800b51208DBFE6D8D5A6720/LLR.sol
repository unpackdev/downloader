// SPDX-License-Identifier: MIT

/*
    __                     __         __                              __    
   / /   ____  ____  ___  / /_  __   / /   ___  ____ ____  ____  ____/ /____
  / /   / __ \/ __ \/ _ \/ / / / /  / /   / _ \/ __ `/ _ \/ __ \/ __  / ___/
 / /___/ /_/ / / / /  __/ / /_/ /  / /___/  __/ /_/ /  __/ / / / /_/ (__  ) 
/_____/\____/_/ /_/\___/_/\__, /  /_____/\___/\__, /\___/_/ /_/\__,_/____/  
                         /____/              /____/   

This ERC721A smart contract is made by syane on 
behalf of Lonely Legends.
Project twitter:    https://twitter.com/LonelyLegendNFT
Site:               https://lonelylegends.io/
For inquiries:      https://twitter.com/syane_eth
*/

pragma solidity ^0.8.9;


import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";

contract LonelyLegendsGenesis is ERC721A, Ownable, ReentrancyGuard {

  using Strings for uint256;

// Configuration 
  uint256 public maxSupply = 5555;
  uint256 public publicSalePrice = 0.069 ether;
  uint256 public teamMintedAmount = 0;
  uint256 public constant teamMintAmount = 55;
  mapping(address => uint) public userMintedPublicSale;
  bool public publicSale = false;
  constructor() ERC721A("Lonely Legends: Genesis", "LLG") {}
  
// Dutch auction configuration

  mapping(address => uint) public userMintedDA;
  mapping(address => paidAmountPerBatch[]) public minterPaidAmountPerBatch;
  struct paidAmountPerBatch {
    uint128 etherPaid;
    uint8 legendsMinted;
  }
  uint256 public startTimeDA = 1650830400;
  uint256 public startPriceDA = 0.3 ether;
  uint256 public decreaseDA = 0.05 ether;
  uint256 public lastPriceDA = 0.1 ether;
  uint256 public decreaseDAFrequency = 900;
  uint256 public allocationDA = 3250;
  uint256 public finalPriceDA;
  bool public dutchAuctionFinished = false;


// Legends list & OG configuration
  bool public preSale = false;
  uint256 public preSaleSold;
  uint256 public preSalePrice = 0.069 ether;
  uint256 public constant preSaleAllocation = 2250;
  mapping(address => uint256) public legendsLists;

// Metadata configuration
  string public MetadataURI;
  string public MetadataURIext = '.json';
  string public preRevealMetadataURI = 'ipfs://QmazRV8kJzDVEjAv5hebg6jFDj3ZdznrdAcefoXRJx6Rw5/';
  bool public metadataReveal = false;
  
  
// Presale functions
  function activatePreSale(bool state) public onlyOwner {
    preSale = state;
  }

  function preSaleMint (uint256 _mintAmount) external payable nonReentrant {
    uint256 remaining = legendsLists[msg.sender];
    require(msg.sender == tx.origin, "You cant mint using a smart contract.");
    require(preSale, "Presale hasn't started yet.");
    require(preSaleSold + _mintAmount <= preSaleAllocation, "The presale is finished!");
    require(remaining != 0 && _mintAmount <= remaining, "You're not allowed to do this.");
    require(msg.value == preSalePrice * _mintAmount, "It costs 0.069 to mint a legend.");
    if (_mintAmount == remaining) {
        delete legendsLists[msg.sender];
    } else {
        legendsLists[msg.sender] = legendsLists[msg.sender] - _mintAmount;
    }
    preSaleSold = preSaleSold + _mintAmount;
    _safeMint(msg.sender, _mintAmount);
  }

  function setlegendsList(address[] calldata legendsListers, bool ogRank) external onlyOwner {
    uint256 quantity = ogRank ? 2 : 1;
    for (uint256 i; i < legendsListers.length; i++) {
      legendsLists[legendsListers[i]] = quantity;
    }
  }

// Dutch Auction
  function setStartTimeDA(uint256 newStartTimeDA) external onlyOwner {
    startTimeDA = newStartTimeDA;
  }

  function finishDutchAuction(uint256 lastPrice) external onlyOwner {
    dutchAuctionFinished = true;
    finalPriceDA = lastPrice;
  }

  function currentDAPrice() public view returns (uint256) {
    require(block.timestamp >= startTimeDA, "We haven't started yet legend.");
    if (finalPriceDA > 0) return finalPriceDA;
      uint256 timeSinceStart = block.timestamp - startTimeDA;
      uint256 decrementsSinceStart = timeSinceStart / decreaseDAFrequency;
      uint256 totalDecrement = decrementsSinceStart * decreaseDA; 
    if (totalDecrement >= startPriceDA - lastPriceDA) {
      return lastPriceDA;
    }
    return startPriceDA - totalDecrement;
  }

  function dutchAuctionMint(uint8 _mintAmount) public payable nonReentrant {    
    require(block.timestamp >= startTimeDA, "We haven't started yet legend.");
    require(!dutchAuctionFinished, "The dutch auction is over.");
    require(_mintAmount > 0 && _mintAmount <= 5, "You can only mint 5 legends per transaction.");
    require(userMintedDA[msg.sender] + _mintAmount <= 5, "You can only mint 5 Legends during the Dutch Auction.");

    uint256 _currentDAPrice = currentDAPrice();

    require(msg.value >= _mintAmount * _currentDAPrice, "Insufficient amount of ETH.");
    require(totalSupply() + _mintAmount <= allocationDA, "This amount exceeds the allocation.");
    require(totalSupply() + _mintAmount <= maxSupply - (teamMintAmount - teamMintedAmount), "This amount exceeds the allocation.");
    require(msg.sender == tx.origin, "You cant mint using a smart contract.");
        
    if (totalSupply() + _mintAmount == allocationDA)
      finalPriceDA = _currentDAPrice;

    minterPaidAmountPerBatch[msg.sender].push(paidAmountPerBatch(uint128(msg.value), _mintAmount));
    userMintedDA[msg.sender] += _mintAmount;

    _safeMint(msg.sender, _mintAmount);
  }

  function refundETH() public nonReentrant {
    require(finalPriceDA > 0, "Dutch auction is still ongoing.");
    require(msg.sender == tx.origin, "Only use this function from a wallet.");
    uint256 totalRefundAmount;
    for (uint256 i = minterPaidAmountPerBatch[msg.sender].length; i > 0; i--) {
    uint256 expectedPrice = minterPaidAmountPerBatch[msg.sender][i - 1].legendsMinted * finalPriceDA;
    uint256 refund = minterPaidAmountPerBatch[msg.sender][i - 1].etherPaid - expectedPrice;
    minterPaidAmountPerBatch[msg.sender].pop();
    totalRefundAmount += refund;
    }
    (bool success, ) = payable(msg.sender).call{value: totalRefundAmount}("");
    require(success, "Something went wrong.");
  }

// Team Mint function

  function teamMint(address to, uint256 _mintAmount) external onlyOwner {
    require(teamMintedAmount + _mintAmount <= teamMintAmount, "The team is allowed to mint 55 legends.");
    teamMintedAmount+= _mintAmount;
    _safeMint(to, _mintAmount); 
  }

// Public Sale functions
  function activatePublicSale(bool state) public onlyOwner {
    publicSale = state;
  }

  function publicSaleMint(uint256 _mintAmount) external payable nonReentrant {
    require(msg.sender == tx.origin, "You cant mint using a smart contract.");
    require(publicSale, "There is no public sale ongoing right now.");
    require(_mintAmount > 0 && _mintAmount <= 5, "You can only mint 5 legends per transaction.");
    require(userMintedPublicSale[msg.sender] + _mintAmount <= 5, "You can only mint 5 Legends during the public sale.");
    require(msg.value == publicSalePrice * _mintAmount, "It costs 0.069 to mint a legend.");
    require(totalSupply() + _mintAmount <= maxSupply - (teamMintAmount - teamMintedAmount), "Try a lower amount of legends.");
    userMintedPublicSale[msg.sender] += _mintAmount;
    _safeMint(msg.sender, _mintAmount);
  }

// Later to be used for airdrops.

  function walletOfOwner(address _owner) public view returns (uint256[] memory) {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = _startTokenId();
    uint256 ownedTokenIndex = 0;
    address latestOwnerAddress;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
      TokenOwnership memory ownership = _ownerships[currentTokenId];

      if (!ownership.burned && ownership.addr != address(0)) {
        latestOwnerAddress = ownership.addr;
      }

      if (latestOwnerAddress == _owner) {
        ownedTokenIds[ownedTokenIndex] = currentTokenId;

        ownedTokenIndex++;
      }

      currentTokenId++;
    }

    return ownedTokenIds;
  }

// Metadata functions

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    if (metadataReveal == false) {
      return preRevealMetadataURI;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), MetadataURIext))
        : '';
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return MetadataURI;
  }

  function revealMetadata(bool state) public onlyOwner {
    metadataReveal = state;
  }

  function setHiddenMetadataUri(string memory hiddenMetadataUri) public onlyOwner {
   preRevealMetadataURI = hiddenMetadataUri;
  }

  function setMetadataURI(string memory newMetadataURI) public onlyOwner {
    MetadataURI = newMetadataURI;
  }

// Function to withdraw funds
  function transferFunds() public onlyOwner nonReentrant {
    (bool os, ) = payable(0x70D8f886B4852A02B5a332DcE07C9917F0aDd22d).call{value: address(this).balance}('');
    require(os);
  }
}