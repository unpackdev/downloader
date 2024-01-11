// SPDX-License-Identifier: GPL-3.0


pragma solidity >=0.7.0 <0.9.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ERC2981.sol";



contract NFT is ERC721Enumerable, Ownable, ERC2981 {
  using Strings for uint256;

  string private baseURI;
  string private notRevealedUri;
  uint256 private initialCost = 0.25 ether;
  uint256 public initialSupply = 200;
  uint256 private finalCost = 0.5 ether;
  uint256 public maxSupply =  1440;
  uint256 public nftMetaDataRevealTime = block.timestamp + 1 weeks;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    string memory _initNotRevealedUri
  ) ERC721(_name, _symbol){
    setBaseURI(_initBaseURI);
    setNotRevealedURI(_initNotRevealedUri);
    _setDefaultRoyalty(owner(),900);

  }

  
      function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

  
    // function _burn(uint256 tokenId) internal virtual override {
    //     super._burn(tokenId);
    //     _resetTokenRoyalty(tokenId);
    // }

    
    function setRoyaltyPercentage(uint96 _percentage) public onlyOwner{
      require (_percentage >= 0 && _percentage <=100, "Royalty percentage should be between 0 and 100");
    _setDefaultRoyalty(owner(),_percentage*100);

    } 

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // public
  function mint() public payable {
    uint256 supply = totalSupply();
    require(supply < maxSupply, "max NFT limit exceeded");


    if (msg.sender != owner()) {

      require (msg.value >= getCost(), "insufficient funds");

    }

    
    (bool os, ) = payable(owner()).call{value: msg.value}("");
    require(os);

      _safeMint(msg.sender, supply);
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
      "ERC721Metadata: URI query for nonexistent token"
    );
    
    if (block.timestamp  < nftMetaDataRevealTime){
     return notRevealedUri;
     }
    

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString()))
        : "";
  }


 function getCost() public view returns (uint256) {
    if (totalSupply() <initialSupply ){
      return initialCost;
    }
    else {
      return finalCost;
    }
  }


  
  function setNftMetaDataRevealTime(uint256 _secondsFromNow) public onlyOwner {
    nftMetaDataRevealTime = block.timestamp + _secondsFromNow;
  }
  

   function setInitialSupply(uint256 _initialSupply) public onlyOwner {
    require (_initialSupply <= maxSupply && _initialSupply > 0, "Initial supply has to be greater than 0 but not greater than max supply");
    initialSupply = _initialSupply;
  }
  
  
  function setInitialCost(uint256 _newCost) public onlyOwner {
    initialCost = _newCost;
  }

  function setFinalCost(uint256 _newCost) public onlyOwner {
    finalCost = _newCost;
  }


  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }


  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }


  function withdraw() public payable onlyOwner {

    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }


   function withdrawableAmount() public view onlyOwner returns(uint256) {
   return address(this).balance;
  }


}