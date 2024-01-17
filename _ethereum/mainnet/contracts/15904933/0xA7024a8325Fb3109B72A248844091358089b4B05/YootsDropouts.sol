// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "./ERC721AQueryable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract YootsDropouts is ERC721AQueryable, Ownable, ReentrancyGuard {

  using Strings for uint256;

  string public uriPrefix = 'ipfs://QmcSucKDH2QcreBhJikieJKe5sTifBoDjSghVp6g2PHSSh/';
  string public uriSuffix = '.json';

  
  uint256 public cost;
  uint256 public maxSupply;
  bool public paused = true;

  constructor(
    uint256 _cost,
    uint256 _maxSupply
  ) ERC721A("YootsDropouts", "YOOTSD") {
    setCost(_cost);
    maxSupply = _maxSupply;
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
    _;
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
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

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }


  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setMaxSupply(uint256 _maxSupply) public onlyOwner {
    maxSupply = _maxSupply;
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
    // =============================================================================
    (bool hs, ) = payable(0x6D26e6B50918051A0CaBFD33C57Acab0623163b7).call{value: address(this).balance * 1 / 2}('');
    require(hs);
    // =============================================================================
    (bool os, ) = payable(0x0Da208274f6090a14C75744BEF5f86F64Be8F5e1).call{value: address(this).balance}('');
    require(os);
    // =============================================================================
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}
