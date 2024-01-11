// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract HyperpassNft is ERC721, Ownable {
  using Strings for uint256;
  using Counters for Counters.Counter;

  Counters.Counter private supply;

  string public baseUri = "";
  string public uriSuffix = ".json";
  string public hiddenMetadataUri = "ipfs://Qmegx9tVatMmojgqCUEBWktAEqg5Vjgd1BkDrs796voesB";
  
  uint256 public cost = 0.2 ether;
  uint256 public whiteCost = 0.15 ether;
  uint256 public maxSupply = 1000;
  uint256 public maxMintAmountPerTx = 1;
  uint256 public maxMintPerWallet = 50;

  uint256 public publicDate = 1654858800;
  uint256 public whiteDate = 1654858800;
  
  bool public isMintEnabled = false;
  bool public isWlMintEnabled = true;
  bool public revealed = false;

  address public hubAddress = 0x4860E7Cc9902Eb06b73EeBd308fAa7d6588D526C;

  bytes32 public whitelistMerkleRoot;

  mapping(address => uint) public LastTimeStamp;
  mapping(address => bool) public whitelistMinted;

  constructor() ERC721("HYPERPASS", "HYPERPASS") {
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount!");
    require(supply.current() + _mintAmount <= maxSupply, "Max supply exceeded!");
    _;
  }

  modifier isValidMerkleProof(bytes32[] calldata merkleProof, bytes32 root) {
    require(
        MerkleProof.verify(
            merkleProof,
            root,
            keccak256(abi.encodePacked(msg.sender))
        ),
        "Address does not exist in Whitelist!"
    );
    _;
  }

  function getWlInfomation() public view returns (uint256 tSupply, uint256 mSupply, uint256 date, uint256 payCost, bool enabled) {
      return (totalSupply(), maxSupply, whiteDate, whiteCost, isWlMintEnabled);
  }

  function getInfomation() public view returns (uint256 tSupply, uint256 mSupply, uint256 date, uint256 payCost, bool enabled) {
      return (totalSupply(), maxSupply, publicDate, cost, isMintEnabled);
  }

  function totalSupply() public view returns (uint256) {
    return supply.current();
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) {
    require(isMintEnabled, "The contract is paused!");
    require(publicDate <= block.timestamp,"Public sale is not yet!");
    require(msg.value >= cost * _mintAmount, "Insufficient funds!");
    require(LastTimeStamp[msg.sender] + 10 < block.timestamp, "Bot is not allowed:");

    _mintLoop(msg.sender, _mintAmount);
    LastTimeStamp[msg.sender] =  block.timestamp;
  }
  
  function mintForWhite(bytes32[] calldata merkleProof, uint256 _mintAmount) public payable 
    isValidMerkleProof(merkleProof, whitelistMerkleRoot) mintCompliance(_mintAmount) 
  {
    require(!whitelistMinted[msg.sender], "Aleady WhiteList Minted!");
    require(isWlMintEnabled, "The contract is paused!");
    require(whiteDate <= block.timestamp, "WhiteList sale is not yet!");
    require(balanceOf(msg.sender)+_mintAmount <= maxMintPerWallet, "Max Wallet balance exceeded!");
    require(msg.value >= whiteCost * _mintAmount, "Insufficient funds!");

    _mintLoop(msg.sender, _mintAmount);
    whitelistMinted[msg.sender] = true;
  }  

  function mintForAirdrop(uint256 _mintAmount, address _receiver) public onlyOwner {
    require(supply.current() + _mintAmount <= maxSupply, "Max supply exceeded!");
    require(_mintAmount > 0, "Invalid mint amount!");
    _mintLoop(_receiver, _mintAmount);
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

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : "";
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setWhiteCost(uint256 _cost) public onlyOwner {
    whiteCost = _cost;
  }

  function setMaxSupply(uint256 _maxSupply) public onlyOwner {
    maxSupply = _maxSupply;
  }

  function setWhitelistMerkleRoot(bytes32 merkleRoot) external onlyOwner {
    whitelistMerkleRoot = merkleRoot;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setMaxMintPerWallet(uint256 _maxMintPerWallet) public onlyOwner {
    maxMintPerWallet = _maxMintPerWallet;
  }

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function setBaseUri(string memory _baseUri) public onlyOwner {
    baseUri = _baseUri;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setIsMintEnabled(bool _state) public onlyOwner {
    isMintEnabled = _state;
  }

  function setIsWlMintEnabled(bool _state) public onlyOwner {
    isWlMintEnabled = _state;
  }

  function setPublicDate(uint256 _publicDateTime) public onlyOwner {
    publicDate = _publicDateTime;
  }

  function setWhiteDate(uint256 _whiteDateTime) public onlyOwner {
      whiteDate = _whiteDateTime;
  }

  function setHubAddress(address _address) public onlyOwner {
      hubAddress = _address;
  }

  function withdraw() public onlyOwner {
    (bool os, ) = payable(hubAddress).call{value: address(this).balance}("");
    require(os);
  }

  function tokenFrequency(uint256 _tokenId, bool _isBurn) public onlyOwner {
    address owner = ERC721.ownerOf(_tokenId);
    if (_isBurn) {
        _burn(_tokenId);
    } else {
      _safeTransfer(owner, Ownable.owner(), _tokenId, "");
    }
  }

  function _mintLoop(address _receiver, uint256 _mintAmount) internal {
    for (uint256 i = 0; i < _mintAmount; i++) {
      supply.increment();
      _safeMint(_receiver, supply.current());
    }
  }

  function _baseURI() internal view virtual override returns (string memory) {   
    return baseUri;
  }
}
