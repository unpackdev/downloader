// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./ERC721AQueryable.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract LionKingAtJob is ERC721AQueryable, Ownable {
  string public baseURI;
  string public baseExtension = ".json";
  string public notRevealedUri;
  uint256 public cost = 77000000000000000;
  uint256 public maxSupply = 10000;
  bool public revealed = false;
  bool public presale = false;
  bool public publicsale = false;

  bytes32 public whitelistRoot;

  constructor() ERC721A("Lion King at Job", "LKAJ") {
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

  // ====== public ======
  function mint(uint256 _mintAmount) public payable callerIsUser {
    // Is publicsale active
    require(publicsale, "publicsale is not active");
    //

    // Amount and payment control
    uint256 supply = totalSupply();
    require(_mintAmount > 0, "need to mint at least 1 NFT");
    require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");
    require(msg.value >= cost * _mintAmount, "insufficient funds");
    //

    _safeMint(msg.sender, _mintAmount);
  }

  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable callerIsUser {
    // Is presale active
    require(presale, "presale is not active");
    //

    // Whitelist Requires
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(MerkleProof.verify(_merkleProof, whitelistRoot, leaf), "user is not whitelisted");
    //

    // Amount and payments control
    uint256 supply = totalSupply();
    require(_mintAmount > 0, "need to mint at least 1 NFT");
    require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");
    require(msg.value >= cost * _mintAmount, "insufficient funds");
    //
    
    _safeMint(msg.sender, _mintAmount);
  }

  function ownerMint(uint256 _mintAmount) public onlyOwner {
    // Amount Control
    uint256 supply = totalSupply();
    require(_mintAmount > 0, "need to mint at least 1 NFT");
    require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");
    //

    _safeMint(msg.sender, _mintAmount);
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

  // Whitelist and OG roots (presale)
  function setWhitelistRoot(bytes32 _whitelistRoot) public onlyOwner{
    whitelistRoot = _whitelistRoot;
  }
  //
  
  // Max Mint Amounts - Cost
  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
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

  // Sale states
  function setPresale() public onlyOwner {
    presale = !presale;
  }

  function setPublicsale() public onlyOwner {
    publicsale = !publicsale;
  }
  //
 
  function withdraw() public payable onlyOwner {
    // =============================================================================
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
    // =============================================================================
  }
}