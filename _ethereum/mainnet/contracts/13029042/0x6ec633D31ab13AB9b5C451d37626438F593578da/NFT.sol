// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./ERC721.sol";
import "./Ownable.sol";
import "./IReward.sol";
import "./IRandom.sol";

contract NFT is ERC721, Ownable {

  string public baseURI;
  IReward public reward;
  IRandom public random;
  uint256 public tokenCounter;
  uint256 public timeOfLastWinner;

  constructor(address _reward, address _random, string memory _URI) ERC721("The Lucky Bastards Lotto", "LBL") {
    reward = IReward(_reward);
    random = IRandom(_random);
    baseURI = _URI;
    timeOfLastWinner = block.timestamp;
  }

  function setWinner() public {
      // should pass at least 1 week to set new winner
      if(block.timestamp > timeOfLastWinner + 604800 && tokenCounter != 0) {
          IRandom _random = random;
          _random.regenerateHash();
          reward.distribute(ERC721.ownerOf(_random.rand(tokenCounter)));
          timeOfLastWinner = block.timestamp;
      } else {
        random.regenerateHash();
      }
  }

  function _baseURI() internal view override virtual returns(string memory) {
    return baseURI;
  }

  function setBaseURI(string memory _URI) onlyOwner external {
    baseURI = _URI;
  }

  function mint(address[] memory _to) onlyOwner external {
    uint256 _length = _to.length; 
    for(uint8 i; i < _length; ++i) {
      ERC721._mint(_to[i], tokenCounter);
      ++tokenCounter;
    }
    require(tokenCounter <= 2500, "LimitExceeded");
  }

  // adding call of set winner for all standart function
  function approve(address _to, uint256 _tokenId) public virtual override {
    setWinner();
    ERC721.approve(_to, _tokenId);
  }

  function setApprovalForAll(address _operator, bool _approved) public virtual override {
    setWinner();
    ERC721.setApprovalForAll(_operator, _approved);
  }

  function transferFrom(address _from, address _to, uint256 _tokenId) public virtual override { 
    setWinner();
    ERC721.transferFrom(_from, _to, _tokenId);
  }

  function safeTransferFrom(address _from, address _to, uint256 _tokenId) public virtual override {
    setWinner();
    ERC721.safeTransferFrom(_from, _to, _tokenId);
  }

  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) public virtual override {
    setWinner();
    ERC721.safeTransferFrom(_from, _to, _tokenId, _data);
  }
}
