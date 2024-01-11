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
import "./ReentrancyGuard.sol";

contract LonelyLegendsGenesis is ERC721A, Ownable, ReentrancyGuard {

  using Strings for uint256;

// Configuration 
  uint256 public maxSupply = 2750;
  constructor() ERC721A("Lonely Legends: Genesis", "LLG") {}


// Legends list/OG & Holders configuration
  bool public preSale = false;
  mapping(address => uint256) public legendsLists;
  address[] public holderAddresses;
  mapping(address => uint) public userMintedHolderSale;

// Metadata configuration
  string public MetadataURI;
  string public MetadataURIext = '.json';
  string public preRevealMetadataURI = 'ipfs://QmazRV8kJzDVEjAv5hebg6jFDj3ZdznrdAcefoXRJx6Rw5/';
  bool public metadataReveal = false;
  
  
// Presale functions
  function activatePreSale(bool state) public onlyOwner {
    preSale = state;
  }
  
  function holderUsers(address[] calldata _users) public onlyOwner {
    delete holderAddresses;
    holderAddresses = _users;
  }
    
  function isHolder(address _user) public view returns (bool) {
    for (uint i = 0; i < holderAddresses.length; i++) {
      if (holderAddresses[i] == _user) {
          return true;
      }
    }
    return false;
  }

  function holderMint(uint256 _mintAmount) external nonReentrant {
    uint256 remaining = legendsLists[msg.sender];
    require(preSale, "There is no sale ongoing right now.");
    require(isHolder(msg.sender), "You're not a holder");
    require(_mintAmount > 0 && _mintAmount <= (2 + remaining), "You can only mint 2 legends per transaction.");
    require(userMintedHolderSale[msg.sender] + _mintAmount <= (2 + remaining), "You can only mint 2 Legends during the holder sale.");
    require(totalSupply() + _mintAmount <= maxSupply, "Try a lower amount of legends.");
   
    // This can be higher than the remaining count for the WL spot
    // Thus I think it's better to seperate both functions
    if(remaining > 0) {
        if (_mintAmount >= remaining) {
            delete legendsLists[msg.sender];
            userMintedHolderSale[msg.sender] += _mintAmount - remaining;
        } else  {
            legendsLists[msg.sender] = legendsLists[msg.sender] - _mintAmount;
            userMintedHolderSale[msg.sender] += _mintAmount - legendsLists[msg.sender];
        }
    } else {
         userMintedHolderSale[msg.sender] += _mintAmount;
    }
   
    _safeMint(msg.sender, _mintAmount);
  }

  function setMaxSupply(uint256 _newSupply) public onlyOwner {
    maxSupply = _newSupply;
  }

  function preSaleMint (uint256 _mintAmount) external nonReentrant {
    uint256 remaining = legendsLists[msg.sender];
    require(msg.sender == tx.origin, "You cant mint using a smart contract.");
    require(preSale, "Presale hasn't started yet.");
    require(!isHolder(msg.sender), "Holders cannot use the presale mint.");
    require(totalSupply() + _mintAmount <= maxSupply, "The presale is finished!");
    require(remaining != 0 && _mintAmount <= remaining, "You're not allowed to do this.");
    if (_mintAmount == remaining) {
        delete legendsLists[msg.sender];
    } else {
        legendsLists[msg.sender] = legendsLists[msg.sender] - _mintAmount;
    }
    
    _safeMint(msg.sender, _mintAmount);
  }

  function setlegendsList(address[] calldata legendsListers, bool OGRank) external onlyOwner {
    uint256 quantity = OGRank ? 2 : 1;
    for (uint256 i; i < legendsListers.length; i++) {
      legendsLists[legendsListers[i]] = quantity;
    }
  }

// Team mint functions

  function teamMint(uint256 _mintAmount) external onlyOwner {
    require(totalSupply() + _mintAmount <= maxSupply, "Try a lower amount of legends.");
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