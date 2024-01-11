// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract IllogicalLogic is ERC721, ERC721URIStorage, Ownable, ReentrancyGuard {

  using Strings for uint256;
  using Counters for Counters.Counter;
  Counters.Counter private supply;

  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;

  bool public paused = true;

  // add different type of NFT in the same contract
  struct NType {
        string nftUri;
        uint256 price;
  }

   uint256 public constant maxNtype = 3;  //initial array to support max number of NFT type
   NType[maxNtype] public nTypes;  //means NFTtype range from 0,1,2 < masNType.
   
  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerTx

  ) ERC721(_tokenName, _tokenSymbol) {
    maxSupply = _maxSupply;
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function totalSupply() public view returns (uint256) {
    return supply.current();
  }

  function setNtype(uint256 _nTypeIndex, string memory _nftUri, uint256 _price) public onlyOwner {
        //index shall range from 0 to maxNtype -1
    require( _nTypeIndex >= 0 && _nTypeIndex < maxNtype, "The NFTType is not defined!");
    nTypes[_nTypeIndex].nftUri = _nftUri;
    nTypes[_nTypeIndex].price = _price;
  }
  
  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setmaxSupply(uint256 _maxSupply) public onlyOwner {
    maxSupply = _maxSupply;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

  function _mintLoop(address _receiver, uint256 _mintAmount,string memory _tockenURI) internal {
    for (uint256 i = 0; i < _mintAmount; i++) {
      supply.increment();
      _safeMint(_receiver, supply.current());
      _setTokenURI(supply.current(), _tockenURI);
    }
  }

  function mint(uint256 _mintAmount, uint256 _nTypeIndex) public payable  {
    require(!paused, "The contract is paused!");
    require(_nTypeIndex < maxNtype, "The NFTType is not defined!");
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount!");
    require(supply.current() + _mintAmount <= maxSupply, "Sales Closed, No longer allowed to Mint!");
    require(msg.value >= nTypes[_nTypeIndex].price * _mintAmount, "Insufficient funds!");

    string memory _tokenURI = nTypes[_nTypeIndex].nftUri;
    _mintLoop(msg.sender, _mintAmount, _tokenURI);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver, uint256 _nTypeIndex) public  onlyOwner {
    require(_nTypeIndex >= 0 && _nTypeIndex < maxNtype, "The NFTType is not defined!");
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount!");
    require(supply.current() + _mintAmount <= maxSupply, "Sales Closed, No longer allowed to Mint!");
    string memory _tokenURI = nTypes[_nTypeIndex].nftUri;
    _mintLoop(_receiver, _mintAmount, _tokenURI);
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory) {
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

  //override _burn() as required by ERC721storage
  function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
    super._burn(tokenId);
  }

  function withdraw() public onlyOwner nonReentrant {
    // This will transfer the remaining contract balance to the owner.
    // Do not remove this otherwise you will not be able to withdraw the funds.
    // =============================================================================
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
    // =============================================================================
  }

}
