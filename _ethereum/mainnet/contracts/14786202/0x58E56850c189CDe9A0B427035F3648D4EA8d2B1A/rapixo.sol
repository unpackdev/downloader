// SPDX-License-Identifier: MIT

//author: dattaraj guttedar || twitter:dattarajguttedr
// www.degen.rocks || twitter:degen_rocks


pragma solidity >=0.7.0 <0.9.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";


contract Rapixo is ERC721, Ownable {
  using Strings for uint256;
  using Counters for Counters.Counter;

  Counters.Counter private supply;

  string public uriPrefix = "";
  string public uriSuffix = ".json";
  string public hiddenMetadataUri;
  
  uint256 public cost = 0.077 ether;
  uint256 public maxSupply = 777;
  uint256 public maxMintAmount = 2;
  uint256 public OGMintAmount = 3;
  uint256 public premintSupply = 777;

  bool public paused = true;
  bool public revealed = false;
  bool public onlyWhitelisted = true;

  bytes32 public root;
  bytes32 public OGroot;

  mapping(address => uint256) public addressMintedBalance;

  constructor() ERC721("Rapixo", "Rapixo") {
    setHiddenMetadataUri("ipfs://Qmcu2KBuiEggbTQKAEn7pHJ7vzpQtXDiN5WkEzGMDHauj3");
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmount, "Invalid mint amount!");
    require(supply.current() + _mintAmount <= maxSupply, "Max supply exceeded!");
    _;
  }

    modifier OGmintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= OGMintAmount, "Invalid mint amount!");
    require(supply.current() + _mintAmount <= maxSupply, "Max supply exceeded!");
    _;
  }

  function totalSupply() public view returns (uint256) {
    return supply.current();
  }

  function mint(uint256 _mintAmount,bytes32[] calldata proof) public payable mintCompliance(_mintAmount) {
    require(!paused, "The contract is paused!");
    require(msg.value >= cost * _mintAmount, "Insufficient funds!");

    if(onlyWhitelisted == true){
    require(_verify(_leaf(msg.sender),root, proof) != false, "Invalid merkle proof");
    require(supply.current() + _mintAmount <= premintSupply, "Max premint supply exceeded!");
    }

    uint256 ownerMintedCount = addressMintedBalance[msg.sender];
    require(ownerMintedCount + _mintAmount <= maxMintAmount, "max NFT per address exceeded");
    
    _mintLoop(msg.sender, _mintAmount);
    
  }

    function OGmint(uint256 _mintAmount,bytes32[] calldata proof) public payable OGmintCompliance(_mintAmount) {
    require(!paused, "The contract is paused!");
    require(msg.value >= cost * _mintAmount, "Insufficient funds!");

    if(onlyWhitelisted == true){
    require(_verify(_leaf(msg.sender),OGroot, proof) != false, "Invalid merkle proof");
    require(supply.current() + _mintAmount <= premintSupply, "Max premint supply exceeded!");
    }

    uint256 ownerMintedCount = addressMintedBalance[msg.sender];
    require(ownerMintedCount + _mintAmount <= maxMintAmount, "max NFT per address exceeded");
    
    _mintLoop(msg.sender, _mintAmount);
    
  }
  
  function mintForAddress(uint256 _mintAmount, address  _receiver) public onlyOwner {
    _mintLoop(_receiver, _mintAmount);
  }

  function Airdrop(uint256 [] memory _MintAmount, address[]memory _Receiver) public onlyOwner {
    for(uint256 i=0 ;i < _MintAmount.length;i++ ){
      _mintLoop(_Receiver[i], _MintAmount[i]);
    }
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = 1;
    uint256 ownedTokenIndex = 0;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
      address currentTokenOwner = ownerOf(currentTokenId);

      if (currentTokenOwner == _owner) {
        ownedTokenIds[ownedTokenIndex] = currentTokenId;

        ownedTokenIndex++;
      }

      currentTokenId++;
    }

    return ownedTokenIds;
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
       return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI(); 
    return bytes(currentBaseURI).length > 0
      ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : "";
    }

    function _leaf(address account)
    public pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(account));
    }

    function _verify(bytes32 leaf,bytes32 _root ,bytes32[] memory proof)
    public view returns (bool)
    {
        return MerkleProof.verify(proof,_root, leaf);
    }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function addroot(bytes32 _root)public onlyOwner{
      root = _root;
  }

  function addOGroot(bytes32 _OGroot)public onlyOwner{
      OGroot = _OGroot;
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setwhitelisted(bool _state)public onlyOwner{
      onlyWhitelisted = _state;
  }

  function setmaxMintAmount(uint256 _maxMintAmount) public onlyOwner {
    maxMintAmount = _maxMintAmount;
  }

  function setOGmaxMintAmount(uint256 _maxMintAmount) public onlyOwner {
    maxMintAmount = _maxMintAmount;
  }

  function setpreMintsupply(uint256 _MaxMintAmount) public onlyOwner {
    premintSupply = _MaxMintAmount;
  }

  function setsupply(uint256 _supply) public onlyOwner {
    maxSupply = _supply;
  }

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function Totalminted() public view returns(uint256){
    return totalSupply();
  }

  function getcost() public view returns(uint256){
      return cost;
  }

  function withdraw(address _address) public onlyOwner {
    // This will transfer the remaining contract balance to the owner.
    // Do not remove this otherwise you will not be able to withdraw the funds.
    // =============================================================================
    (bool os, ) = payable(_address).call{value: address(this).balance}("");
    require(os);
    // =============================================================================
  }

  function _mintLoop(address _receiver, uint256 _mintAmount) internal {
    for (uint256 i = 0; i < _mintAmount; i++) {
      addressMintedBalance[msg.sender]++;
      supply.increment();
      _safeMint(_receiver, supply.current());
    }
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}

