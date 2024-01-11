// SPDX-License-Identifier: GPL-3.0

//
//  Created by NAJI
//                         ________    ________
//  ||\   //      /\      |---  ---|  |---  ---|
//  ||\\  ||     //\\         ||          ||
//  || \\ ||    //__\\     _  ||          ||
//  ||  \\||   //----\\    \\_//       ___||___
//  //   \\/  |/      \|    \_/       |---  ---|
// 
//  This is NAJI's Smart Contract.
//  You can contact him with this email. be1512t6@gmail.com
//

pragma solidity ^0.8.3;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

// Contract: DeStorm
// Author: NAJI
// ---- CONTRACT BEGINS HERE ----

contract NFT is ERC721Enumerable, Ownable {

  using Strings for uint256;

  string public baseURI = "https://gateway.pinata.cloud/ipfs/QmQJ7ptxVqNNRyb9yWmi1Upg9mVCFoikiEsR51hqvfuwGC/Camel";
  string public baseExtension = ".json";

  bool public paused = true;
  bool public publicSaleStarted = false;

  uint256 public maxSupply = 1515;

  // Price 
  uint256 public tier1Price = 0.2 ether;
  uint256 public tier2Price = 0.2 ether;
  uint256 public specialPrice = 0.2 ether;
  uint256 public OGPrice = 0.17 ether;

  // Supply 
  uint public tier1OGSupply = 188;  // 188
  uint public tier2OGSupply = 187;  // 187
  uint public tier1Supply = 750 - tier1OGSupply;
  uint public tier2Supply = 750 - tier2OGSupply;
  uint public specialEditionSupply = 15;

  // Minted Supply
  uint public tier1MintedSupply = 0;
  uint public tier2MintedSupply = 0;
  uint public specialEditionMintedSupply = 0;
  uint public tier1OGMintedSupply = 0;
  uint public tier2OGMintedSupply = 0;

  uint public maxPerMintCount = 10;

  address public teamWallet = 0xE7624183DD2CE7245FBE7182589dA9b0c52eA132;

  constructor() ERC721("HALA", "HALA") {
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }
    
  function mintTier1(address _to, uint _mintCount) public payable {
    uint256 supply = totalSupply();
    require(!paused, "NFT mint is paused.");
    require(publicSaleStarted, "You can mint this NFT on the public sale.");
    require(_mintCount <= maxPerMintCount, "You can only 10 NFTs per Transaction.");
    require(supply + _mintCount <= maxSupply, "MaxSupply is limited.");
    require(tier1MintedSupply + _mintCount <= tier1Supply, "Tier 1 NFT limited.");

    if (msg.sender != owner()) {
        require(msg.value >= tier1Price * _mintCount, "Not enough fees to mint.");
    }
    // Mint NFT
    for (uint256 i = 1; i <= _mintCount; i++) {
        tier1MintedSupply ++;
        _safeMint(_to, tier1MintedSupply);
    }
  }

  function mintTier2(address _to, uint _mintCount) public payable {
    uint256 supply = totalSupply();
    require(!paused, "NFT mint is paused.");
    require(publicSaleStarted, "You can mint this NFT on the public sale.");
    require(_mintCount <= maxPerMintCount, "You can only 10 NFTs per Transaction.");
    require(supply + _mintCount <= maxSupply, "MaxSupply is limited.");
    require(tier2MintedSupply + _mintCount <= tier2Supply, "Tier 2 NFT limited."); 
    if (msg.sender != owner()) {
    require(msg.value >= tier2Price * _mintCount, 'Not enough fees to mint.');
    }
    // Mint NFT
    for (uint256 i = 1; i <= _mintCount; i++) {
      tier2MintedSupply ++;
      _safeMint(_to, 750 + tier2MintedSupply);
    }
  }

  function mintSpecial(address _to, uint _mintCount) public payable {
    uint256 supply = totalSupply();
    require(!paused, "NFT mint is paused.");
    require(publicSaleStarted, "You can mint this NFT on the public sale.");
    require(_mintCount <= maxPerMintCount, "You can only 10 NFTs per Transaction.");
    require(supply + _mintCount <= maxSupply, "MaxSupply is limited.");
    require(specialEditionMintedSupply + _mintCount <= specialEditionSupply, "Special Edition NFT limited.");
    if (msg.sender != owner()) {
        require(msg.value >= specialPrice * _mintCount, 'Not enough fees to mint.');
    }
    // Mint NFT
    for (uint256 i = 1; i <= _mintCount; i++) {
        specialEditionMintedSupply ++;
        _safeMint(_to, 1500 + specialEditionMintedSupply);
    }
  }

  function mintOG(address _to, uint _mintCount) public payable {
    uint256 supply = totalSupply();
    require(!paused, "NFT mint is paused.");
    require(_mintCount <= maxPerMintCount, "You can only 10 NFTs per Transaction.");
    require(supply + _mintCount <= maxSupply, "MaxSupply is limited.");
    
    for (uint256 i = 1; i <= _mintCount; i++) {

      if(tier1OGMintedSupply > tier2OGMintedSupply) {
        // Tier 2 OG Mint
        require(tier2OGMintedSupply < tier2OGSupply, "Tier 2 OG Supply limited.");
        if (msg.sender != owner()) {
          require(msg.value >= OGPrice * _mintCount, 'Not enough fees to mint.');
        }
        // Mint NFT
        _safeMint(_to, 1500 - tier2OGMintedSupply);
        tier2OGMintedSupply ++;
      }
      else {
        // Tier 1 OG Mint
        require(tier1OGMintedSupply < tier1OGSupply, "Tier 1 OG Supply limited.");
        if (msg.sender != owner()) {
          require(msg.value >= OGPrice * _mintCount, 'Not enough fees to mint.');
        }
        // Mint NFT
        _safeMint(_to, 750 - tier1OGMintedSupply);
        tier1OGMintedSupply ++;
      }
    }
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent NFT"
    );

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

  
  // This sets the max supply. This will be set to 10,000 by default, although it is changable.
  function setMaxSupply(uint256 _newSupply) public onlyOwner() {
    maxSupply = _newSupply;
  } 
  // This changes the baseURI.
  // Example: If you pass in "https://google.com/", then every new NFT that is minted
  // will have a URI corresponding to the baseURI you passed in.
  // The first NFT you mint would have a URI of "https://google.com/1",
  // The second NFT you mint would have a URI of "https://google.com/2", etc.
  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }
  // This withdraws the contract's balance of ETH to the Owner's (whoever launched the contract) address.
  function withdraw() public payable onlyOwner {
    require(payable(teamWallet).send(address(this).balance));
  }
  // This pauses or unpauses sales.
  function pause(bool _state) public onlyOwner {
    paused = _state;
  }
  // This pauses or unpauses sales.
  function publicSaleStart(bool _state) public onlyOwner {
    publicSaleStarted = _state;
  }
  // This set tier1Price
  function setTier1Price(uint256 _price) public onlyOwner {
    tier1Price = _price;
  }
  // This set tier2Price
  function setTier2Price(uint256 _price) public onlyOwner {
    tier2Price = _price;
  }
  // This set specialPrice
  function setSpecialPrice(uint256 _price) public onlyOwner {
    specialPrice = _price;
  }
  // This set OGPrice
  function setOGPrice(uint256 _price) public onlyOwner {
    OGPrice = _price;
  }
  // This set Team wallet
  function setTeamWallet(address _addr) public onlyOwner {
    teamWallet = _addr;
  }
  // This set maxPerMintCount
  function setMaxPerMintCount(uint256 _count) public onlyOwner {
    maxPerMintCount = _count;
  }
  // This set tier1OGSupply
  function setTier1OGSupply(uint256 _supply) public onlyOwner {
    tier1OGSupply = _supply;
  }
  // This set tier1OGSupply
  function setTier2OGSupply(uint256 _supply) public onlyOwner {
    tier2OGSupply = _supply;
  }

}