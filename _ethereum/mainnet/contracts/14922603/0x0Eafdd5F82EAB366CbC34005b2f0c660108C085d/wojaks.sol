// SPDX-License-Identifier: GPL-3.0

/**

$$\      $$\  $$$$$$\     $$$$$\  $$$$$$\  $$\   $$\       $$\   $$\ $$$$$$$$\ $$$$$$$$\ 
$$ | $\  $$ |$$  __$$\    \__$$ |$$  __$$\ $$ | $$  |      $$$\  $$ |$$  _____|\__$$  __|
$$ |$$$\ $$ |$$ /  $$ |      $$ |$$ /  $$ |$$ |$$  /       $$$$\ $$ |$$ |         $$ |   
$$ $$ $$\$$ |$$ |  $$ |      $$ |$$$$$$$$ |$$$$$  /        $$ $$\$$ |$$$$$\       $$ |   
$$$$  _$$$$ |$$ |  $$ |$$\   $$ |$$  __$$ |$$  $$<         $$ \$$$$ |$$  __|      $$ |   
$$$  / \$$$ |$$ |  $$ |$$ |  $$ |$$ |  $$ |$$ |\$$\        $$ |\$$$ |$$ |         $$ |   
$$  /   \$$ | $$$$$$  |\$$$$$$  |$$ |  $$ |$$ | \$$\       $$ | \$$ |$$ |         $$ |   
\__/     \__| \______/  \______/ \__|  \__|\__|  \__|      \__|  \__|\__|         \__|   

**/

pragma solidity >=0.7.0 <0.9.0;

import "./ERC721A.sol";
import "./Ownable.sol";

contract Wojaks is ERC721A, Ownable {
  using Strings for uint256;

  string public baseURI;
  string public baseExtension = ".json";
  uint256 public cost = 0 ether;
  uint256 public maxSupply = 4269;
  uint256 public maxMintAmount = 10;
  bool public paused = false;
  bool public revealed = false;
  string public notRevealedUri;


  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    string memory _initNotRevealedUri
  ) ERC721A(_name, _symbol) {
    setBaseURI(_initBaseURI);
    setNotRevealedURI(_initNotRevealedUri);
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // public
  function mint(uint256 _mintAmount) public payable {
    uint256 supply = totalSupply();
    require(!paused);
    require(_mintAmount > 0);
    require(_mintAmount <= maxMintAmount);
    require(supply + _mintAmount <= maxSupply);

    _safeMint(msg.sender, _mintAmount);

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
    
    if(revealed == false) {
        return notRevealedUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

  //only owner
  function reveal() public onlyOwner {
      revealed = true;
  }
  
  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
    maxMintAmount = _newmaxMintAmount;
  }
  
  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }

  function withdraw() public payable onlyOwner {
  
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
    
  }
}