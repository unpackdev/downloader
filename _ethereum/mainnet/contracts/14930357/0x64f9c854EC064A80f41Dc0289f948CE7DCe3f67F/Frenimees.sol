// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "./ERC721AQueryable.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";

contract Frenimees is ERC721AQueryable, Ownable, ReentrancyGuard {

  using Strings for uint256;

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;
  
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;
  uint256 public walletLimit;

  bool public paused = false;
  bool public revealed = false;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _maxSupply,
    uint256 _walletLimit,
    string memory _hiddenMetadataUri
  ) ERC721A(_tokenName, _tokenSymbol) {
    maxSupply = _maxSupply;
    setWalletLimit(_walletLimit);
    setHiddenMetadataUri(_hiddenMetadataUri);
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && balanceOf(_msgSender()) + _mintAmount <= walletLimit, 'Invalid mint amount! or you have reached your wallet limit!');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _;
  }

  function mint(uint256 _mintAmount) public mintCompliance(_mintAmount){
    require(!paused, 'The contract is paused!');
    _safeMint(_msgSender(), _mintAmount);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _safeMint(_receiver, _mintAmount);
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

   function setWalletLimit(uint256 _walletLimit) public onlyOwner {
    walletLimit = _walletLimit;
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

  function withdraw() public onlyOwner nonReentrant {
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}
