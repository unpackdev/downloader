// SPDX-License-Identifier: MIT


pragma solidity >=0.7.0 <0.9.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./ERC2771Context.sol";
import "./MinimalForwarder.sol";

contract SimpleNftGasless is  ERC721, Ownable, ERC2771Context{
  using Strings for uint256;
  using Counters for Counters.Counter;

  
  Counters.Counter private supply;

  string public uriPrefix = "";
  string public uriSuffix = ".json";
  string public hiddenMetadataUri;
  
  
  uint256 public maxSupply = 1000;
  uint256 public maxMintAmountPerTx = 1;

  bool public paused = false;
  bool public revealed = true;
  bool public gasLess = true;
  uint256 public cost = 0.01 ether;

  constructor(MinimalForwarder forwarder) ERC721("Metagency by KRDS", "meta") ERC2771Context(address(forwarder)){
    setHiddenMetadataUri("ipfs://QmZCrLYhTTPYBkz88rraAzsePoESyUiwQtFa5aZBdcBjYE/hidden.json");
    setUriPrefix('ipfs://QmRpUCmqsHaonuwNVF99gFqiFkVTwkRqmYFE8zHuoGwtdM/');
    
  }
  function _msgSender()internal view   override(Context, ERC2771Context) returns (address sender)    {
        sender = ERC2771Context._msgSender();
  }

    /// @inheritdoc	ERC2771Context
  function _msgData() internal  view  override(Context, ERC2771Context)  returns (bytes calldata)   {
        return ERC2771Context._msgData();
   
   }


  
  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount!");
    require(supply.current() + _mintAmount <= maxSupply, "Max supply exceeded!");
    uint256 ownerTokenCount = balanceOf(_msgSender());
    require(ownerTokenCount < maxMintAmountPerTx, "Only 1 NFT allowed per user.");
    
    _;
  }

  function totalSupply() public view returns (uint256) {
    return supply.current();
  }

  
  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) {
    require(!paused, "The contract is paused!");
    if(!gasLess)
    {
      require(msg.value >= cost * _mintAmount, "Insufficient funds!");
      _mintLoop(msg.sender, _mintAmount);
    }
    else
    {
      _mintLoop(_msgSender(), _mintAmount);
    }

    
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
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

  

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
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

  
  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setGasLess(bool _state) public onlyOwner {
    gasLess = _state;
  }

  function withdraw() public onlyOwner {
    // This will transfer the remaining contract balance to the owner.
    // Do not remove this otherwise you will not be able to withdraw the funds.
    // =============================================================================
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
    // =============================================================================
  }

  function _mintLoop(address _receiver, uint256 _mintAmount) internal {
    for (uint256 i = 0; i < _mintAmount; i++) {
      supply.increment();
      _safeMint(_receiver, supply.current());
    }
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}
