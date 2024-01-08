// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Pausable.sol";
import "./PaymentSplitter.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract FlippedPenguinsToken is ERC721, ERC721URIStorage, ERC721Enumerable, Ownable, Pausable, PaymentSplitter, ReentrancyGuard {
  using SafeMath for uint256;

  uint256 public constant TOKEN_LIMIT = 8888;
  uint internal nonce = 0;
  uint[TOKEN_LIMIT] internal indices;

  uint256 private _tokenPrice;
  uint256 private _maxTokensAtOnce = 50;

  uint256[] private _teamShares = [50, 50];
  address[] private _team = [
    0xCE81fdDfdEF44EA5d56944c9CCF2D0EA0f7B604C, // M
    0xF67D0DE7fC3642f78FD2d5B4e50c46E0279C7BBA  // B
  ];

  constructor()
    PaymentSplitter(_team, _teamShares)
    ERC721("Flipped Penguins", "FPG")
  {
    setTokenPrice(10000000000000000);
  }

  function _baseURI() internal override pure returns (string memory) {
    return "https://api.flippedpenguins.io/penguin/";
  }

  function getTokenPrice() public view returns(uint256) {
    return _tokenPrice;
  }

  function setTokenPrice(uint256 _price) public onlyOwner {
    _tokenPrice = _price;
  }

  function togglePaused() public onlyOwner {
    if (paused()) { _unpause(); } else { _pause(); }
  }

  function _newTokenIndex() internal returns (uint256) {
    uint256 totalSize = TOKEN_LIMIT - totalSupply();
    uint256 index = uint(keccak256(abi.encodePacked(nonce, msg.sender, block.difficulty, block.timestamp))) % totalSize;
    uint256 value = 0;
    if (indices[index] != 0) { value = indices[index]; } else { value = index; }
    if (indices[totalSize-1] == 0) { indices[index] = totalSize-1; } else { indices[index] = indices[totalSize-1]; }
    nonce++;
    return value.add(1);
  }

  function _mintRandom(address _to) private {
    uint _tokenID = _newTokenIndex();
    _safeMint(_to, _tokenID);
  }

  function mintMultipleTokens(uint256 _amount) public payable nonReentrant whenNotPaused {
    require(totalSupply().add(_amount) <= TOKEN_LIMIT, "Exceeds max supply of tokens");
    require(_amount <= _maxTokensAtOnce, "Too many tokens");
    require(getTokenPrice().mul(_amount) == msg.value, "Insufficient funds");

    for(uint256 i = 0; i < _amount; i++) {
      _mintRandom(msg.sender);
    }
  }

  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function tokenURI(uint256 tokenId) public view virtual override(ERC721, ERC721URIStorage) returns (string memory) {
    return string(super.tokenURI(tokenId));
  }

  function _burn(uint256 tokenId) internal virtual override(ERC721, ERC721URIStorage) {
    super._burn(tokenId);
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
    return super.supportsInterface(interfaceId);
  }
}
