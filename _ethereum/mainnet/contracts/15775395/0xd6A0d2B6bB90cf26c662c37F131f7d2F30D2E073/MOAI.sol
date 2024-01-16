// SPDX-License-Identifier: UNLICENSED
/*
******************************************************************
                 
                 Moai Suits Collection
  
******************************************************************
       ** Developed by Mishzai, Blockchain Developer @ www.blokedia.io
       ** Audited by Meraj Bugti, Blockchain Developer @ www.blokedia.io
*/
       
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./MerkleProof.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract Moai_Suits_Collection is ERC721A, Ownable {
  using Strings for uint256;

  constructor() ERC721A("Moai Suits Collection", "MSC")  {}
  //uriprefix is the base URI
  string public uriPrefix = "ipfs://QmcrYwbzy5Zycq7zFx6yB593AVME9TRockRrncuwzP29cX/";
  string public uriSuffix = ".json";

  
  // hiddenMetadataUri is the not reveal URI
  string public hiddenMetadataUri= "ipfs://QmPMaemQwnKStoSXAX45KpA2sVWMqKxpk79LturHpstNT8/";
  
  // Max Supply
  uint256 public maxSupply = 7750;
  // Mint Cost
  uint256 public cost = 0.15 ether;

  uint256 public MaxMintAmount = 250;

  bool public PublicMintStarted = false;
  bool public Revealed = false;
  bool public Mintpaused = false;
  bytes32 public merkleRoot;

  modifier mintCompliance(uint256 _mintAmount) {
    require(totalSupply() + _mintAmount <= maxSupply, "Max supply exceeded!");
    require(!Mintpaused, "The contract is paused!");
    require( _mintAmount <= MaxMintAmount , "Exceeds Max mint Per Tx!");
    _;
  }

  function mintPublic(uint256 _mintAmount) public payable mintCompliance(_mintAmount) {
   require(msg.value >= cost * _mintAmount, "Insufficient funds!");
   require(PublicMintStarted, "Public mint is not active");

    _safeMint(msg.sender, _mintAmount);
  }

  function mintWL(uint256 _mintAmount, bytes32[] memory _merkleProof) public payable mintCompliance(_mintAmount) {
    require(msg.value >= cost * _mintAmount, "Insufficient funds!");
    require(!PublicMintStarted, "The Whitelist sale is ended!");
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf),"Invalid Merkle Proof." );
    _safeMint(msg.sender, _mintAmount);
  }

  
  function Airdrop(uint256 _mintAmount, address[] memory _receiver) public onlyOwner {
    for (uint256 i = 0; i < _receiver.length; i++) {
      _safeMint(_receiver[i], _mintAmount);
    }
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory){
    require(_exists(_tokenId),"ERC721Metadata: URI query for nonexistent token");
    if (Revealed == false) {
      return hiddenMetadataUri;}
    string memory currentBaseURI = _baseURI();
    _tokenId = _tokenId+1;
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : "";
  }

  function Reveal_Collection(bool _state) public onlyOwner {
    Revealed = _state;
  }

  function StartPublicSale(bool _state) public onlyOwner {
    PublicMintStarted = _state;
  }

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }
 
  function setPre_revealURI(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function Pause_mint(bool _state) public onlyOwner {
    Mintpaused = _state;
  }

  function withdraw() public onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}