// SPDX-License-Identifier: GPL-3.0

//     ===============     //
//    / canscansncans \    //   
//    | canscansncans |    //   
//    | canscansncans |    //
//    | canscansncans |    //
//    | canscansncans |    //
//    | canscansncans |    //
//    | canscansncans |    //
//    | canscansncans |    //
//    | canscansncans |    //
//    \ canscansncans /    //
//     ===============     // 
//                         //  
//        dev: jive        //


pragma solidity >=0.7.0 <0.9.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract BitcansBeta is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string public baseURI;
  string public baseExtension = ".json";
  string public notRevealedUri;
  uint256 public cost = .01 ether;
  uint256 public maxSupply = 61;
  uint256 public maxMintAmount = 2;
  uint256 public giveawayAmount = 12;
  uint256 public nftPerAddressLimit = 1;
  bool public paused = true;
  bool public revealed = false;

  constructor(
    string memory _initBaseURI,
    string memory _initNotRevealedUri
  ) ERC721("Bitcans Beta", "BITCANSBETA") {
    setBaseURI(_initBaseURI);
    setNotRevealedURI(_initNotRevealedUri);
  }
  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // public
   function mint(address _to, uint256 _mintAmount) public payable {
    uint256 supply = totalSupply();
    require(!paused, "Not open, come back later!");
    require(_mintAmount > 0);
    require(_mintAmount < maxMintAmount, "1 Beer Limit!");
    require(supply + _mintAmount < maxSupply, "Keg is tapped!");

    if (msg.sender != owner()) {
           require(msg.value == cost * _mintAmount, "Insufficient funds!");
    }
    for (uint256 i = 1; i <= _mintAmount; i++) {
      _safeMint(_to, supply + i);
    }
  }

   function devMint(uint256 _mintAmount) public payable {
    require(!paused, "the contract is paused");
    uint256 supply = totalSupply();
    require(supply + _mintAmount < giveawayAmount, "INVALID_QUANTITY");

        for (uint256 i = 0; i < _mintAmount; i++) {
             _safeMint(msg.sender, supply);

            unchecked {
                supply++;
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

function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(_tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    if(revealed == false) {
        return notRevealedUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), baseExtension))
        : "";
  }

  //only owner
  function reveal(bool _state) public onlyOwner {
      revealed = _state;
  }
  
  function setNftPerAddressLimit(uint256 _limit) public onlyOwner {
    nftPerAddressLimit = _limit;
  }
  
  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
    maxMintAmount = _newmaxMintAmount;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }
  
  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }
  
  function withdraw() public payable onlyOwner {
     // =============================================================================
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
    // =============================================================================
  }
}








// Boonk Gang 
// Slim Thic
// Cannons and Dumptrucks
