// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract TheStanleys is ERC721, Ownable {
  using Strings for uint256;
  using Counters for Counters.Counter;
  Counters.Counter private supply;

  string public uriPrefix = "ipfs://";
  string public uriSuffix = ".json";
  string public hiddenUri = "ipfs://QmVtDtUZLgoq1To9GKwRjgQQkhWRUWEJan89BUivoU78o6";
  
  uint256 public cost = 0.05 ether;
  uint256 public maxMintAmountPerTx = 20;
  uint256 public maxSupply = 10000;
  uint256 public availableSupply = 500;
  
  address public multisigWalletAddress = 0xefDD6f65272A344f862C31806eDBdcce31641307;
  
  bool public isPaused = false;
  bool public isRevealed = false;

  constructor() ERC721("The Stanleys", "STAN") {}

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount <= maxMintAmountPerTx, "Exceeded mint amount");
    require(supply.current() + _mintAmount <= availableSupply, "Exceeded available supply");
    _;
  }

  function totalSupply() public view returns (uint256) {
    return supply.current();
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) {
    require(!isPaused, "Mint is paused");
    require(msg.value >= cost * _mintAmount, "Provided insufficient funds");
    _mintLoop(msg.sender, _mintAmount);
  }

  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _mintLoop(_receiver, _mintAmount);
  }

  function walletOfOwner(address _owner) public view returns (uint256[] memory) {
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

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), "ERC721Metadata: URI query for non-existent token");

    if (isRevealed == false) {
      return hiddenUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix)) : "";
  }

  function setIsRevealed(bool _state) public onlyOwner {
    isRevealed = _state;
  }

  function setCost(uint256 _newcost) public onlyOwner {
    cost = _newcost;
  }

  function setIsPaused(bool _state) public onlyOwner {
    isPaused = _state;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setAvailableSupply(uint256 _availableSupply) public onlyOwner {
    require(_availableSupply <= maxSupply, 'Cannot set available supply beyond maximum supply');
    availableSupply = _availableSupply;
  }

  function setHiddenUri(string memory _hiddenUri) public onlyOwner {
    hiddenUri = _hiddenUri;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function withdrawAll() public onlyOwner {
    (bool success, ) = payable(multisigWalletAddress).call{value: address(this).balance}("");
    require(success);
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