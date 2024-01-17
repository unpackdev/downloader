// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./ERC721AQueryable.sol";
import "./Ownable.sol";

contract TreasureCapsule is ERC721AQueryable, Ownable {
  string public baseURI;
  string public baseExtension = ".json";
  string public notRevealedUri;

  uint256 public maxSupply = 20000;
  uint256 public maxMintAmount = 1;

  bool public revealed = false;
  bool public publicsale = false;

  mapping(address => uint256) public publicMintedBalance;

  constructor() ERC721A("Treasure Capsule", "TCPS") {
  }

  // ====== Settings ======
  modifier callerIsUser() {
    require(tx.origin == msg.sender, "cannot be called by a contract");
    _;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }
  
  function _startTokenId() internal pure override returns (uint256){
    return 1;
  }
  //

  // ====== Mint Section ======
  function mint(uint256 _mintAmount) public payable callerIsUser {
    // Is publicsale active
    require(publicsale, "publicsale is not active");
    //

    // Amount controls
    uint256 supply = totalSupply();
    require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");

    require(publicMintedBalance[msg.sender] + _mintAmount <= maxMintAmount, "max NFT limit exceeded per wallet");
    //

    // Increment public minted balance before mint
    publicMintedBalance[msg.sender] += _mintAmount;
    //

    _safeMint(msg.sender, _mintAmount);
  }

  function ownerMint(address _to, uint256 _mintAmount) public onlyOwner {
    // Amount Control
    uint256 supply = totalSupply();
    require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");
    //

    _safeMint(_to, _mintAmount);
  }

  // ====== View ======
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
        ? string(abi.encodePacked(currentBaseURI, _toString(tokenId), baseExtension))
        : "";
  }

  // ====== Only Owner ======
  function reveal() public onlyOwner {
    revealed = true;
  }
  
  // Max Mint Amount
  function setMaxMintAmount(uint256 _newAmount) public onlyOwner {
    maxMintAmount = _newAmount;
  }
  //

  // Metadata
  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }
  
  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }
  //

  // Sale State
  function setPublicsale() public onlyOwner {
    publicsale = !publicsale;
  }
  //

  // Withdraw Funds
  function withdraw() public payable onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }
}