// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./PaymentSplitter.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";

contract ComeToDaddyToken is ERC721, ERC721URIStorage, ERC721Enumerable, Ownable, Pausable, PaymentSplitter, ReentrancyGuard {
  using SafeMath for uint256;

  uint256 public constant TOKEN_LIMIT = 8888;

  uint256 private _maxTokensAtOnce;

  uint internal nonce = 0;
  uint[TOKEN_LIMIT] internal indices;

  uint256 private _tokenPrice;
  uint256[] private _teamShares = [60, 40];
  address[] private _team = [0xa42124D4C69a23602114bF8a61a4d2f081C8Af59, 0xa1c8049521f2b1e6FCC165cFB6E456E195D78699];

  string private __baseURI;

  constructor()
    PaymentSplitter(_team, _teamShares)
    ERC721("Come To Daddy", "C2D")
  {
    setBaseURI("https://api.cometodaddy.io/metadata/");
    setTokenPrice(4e16);
    setMaxTokensAtOnce(20);
  }

  function mintMany(uint256 _amount) public payable nonReentrant whenNotPaused {
    require(totalSupply().add(_amount) <= TOKEN_LIMIT, "Purchase would exceed available supply of tokens");
    require(_amount <= _maxTokensAtOnce, "Too many tokens at once");
    require(getTokenPrice().mul(_amount) == msg.value, "You need to pay the exact price");

    for(uint256 i = 0; i < _amount; i++) {
      _mintOne(msg.sender);
    }
  }

  function _mintOne(address _to) private {
    uint _tokenID = randomIndex();
    _safeMint(_to, _tokenID);
  }

  function devMint(uint256 _amount) public nonReentrant onlyOwner {
    for(uint256 i = 0; i < _amount; i++) {
      _mintOne(msg.sender);
    }
  }

  function randomIndex() internal returns (uint256) {
    uint256 totalSize = TOKEN_LIMIT - totalSupply();
    uint256 index = uint(keccak256(abi.encodePacked(nonce, msg.sender, block.difficulty, block.timestamp))) % totalSize;
    uint256 value = 0;

    if (indices[index] != 0) {
      value = indices[index];
    } else {
      value = index;
    }

    if (indices[totalSize - 1] == 0) {
      indices[index] = totalSize - 1;
    } else {
      indices[index] = indices[totalSize - 1];
    }

    nonce++;

    return value.add(1);
  }

  function maxTokensAtOnce() public view returns (uint256) {
    return _maxTokensAtOnce;
  }

  function setMaxTokensAtOnce(uint256 _count) public onlyOwner {
    _maxTokensAtOnce = _count;
  }

  function _burn(uint256 tokenId) internal virtual override(ERC721, ERC721URIStorage) {
    super._burn(tokenId);
  }

  function tokenURI(uint256 tokenId) public view virtual override(ERC721, ERC721URIStorage) returns (string memory) {
    return super.tokenURI(tokenId);
  }

  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  function togglePaused() public onlyOwner {
    if (paused()) {
      _unpause();
    } else {
      _pause();
    }
  }

  function getTokenPrice() public view returns(uint256) {
    return _tokenPrice;
  }

  function setTokenPrice(uint256 _price) public onlyOwner {
    _tokenPrice = _price;
  }

  function _baseURI() internal override view returns (string memory) {
    return __baseURI;
  }

  function setBaseURI(string memory _value) public onlyOwner {
    __baseURI = _value;
  }
}
