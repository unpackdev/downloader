// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./PaymentSplitter.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";

interface ISpacePunksTreasureKeys {
  function burnKeyForAddress(uint256 typeId, address burnTokenAddress) external;
  function balanceOf(address account, uint256 id) external view returns (uint256);
}

contract EGSToken is ERC721, ERC721URIStorage, ERC721Enumerable, Ownable, Pausable, PaymentSplitter, ReentrancyGuard {
  using SafeMath for uint256;

  uint256 public constant TOKEN_LIMIT = 10001;
  uint256 public constant KEYS_LIMIT = 1000;
  uint256 public constant LAUNCHPAD_PROJECT_ID = 9;

  uint256 public maxTokensAtOnce = 6;
  uint256 public maxTokensPerWallet = 6;

  address private _treasureKeys;

  uint internal nonce = 0;
  uint[TOKEN_LIMIT] internal indices;

  uint256 private _tokenPrice;
  uint256[] private _teamShares = [95, 5];
  address[] private _team = [0xBB8456D66feEba4E81240f9D9B4696e6088CFDd9, 0x10Ed692665Cbe4AA26332d9484765e61dCbFC8a5];

  string private __baseURI;

  constructor()
    PaymentSplitter(_team, _teamShares)
    ERC721("The Exotic Gentlemen Society", "EGS")
  {
    setBaseURI("https://egs-api.herokuapp.com/metadata/");
    setTreasureKeys(0x4bc87F553fcE25bd613a7C31b17d6D224A84c7bF);
    setTokenPrice(2e16);
    _pause();
  }

  function mintWithTreasureKey(uint256 _amount) external nonReentrant whenNotPaused {
    ISpacePunksTreasureKeys keys = ISpacePunksTreasureKeys(_treasureKeys);

    require(keys.balanceOf(msg.sender, LAUNCHPAD_PROJECT_ID) >= _amount, "SPC Treasure Keys: not enough keys");

    for(uint256 i = 0; i < _amount; i++) {
      keys.burnKeyForAddress(LAUNCHPAD_PROJECT_ID, msg.sender);
      _mintOne(msg.sender);
    }
  }

  function mint(uint256 _amount) public payable nonReentrant whenNotPaused {
    require(totalSupply().add(_amount) <= TOKEN_LIMIT - KEYS_LIMIT, "Purchase would exceed available supply of tokens");
    require(_amount <= maxTokensAtOnce, "Too many tokens at once");
    require(balanceOf(msg.sender) <= maxTokensPerWallet, "You can't mint more tokens");
    require(getTokenPrice().mul(_amount) == msg.value, "You need to pay the exact price");

    for(uint256 i = 0; i < _amount; i++) {
      _mintOne(msg.sender);
    }
  }

  function _mintOne(address _to) private {
    uint _tokenID = randomIndex();
    _safeMint(_to, _tokenID);
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

  function setMaxTokensAtOnce(uint256 _count) public onlyOwner {
    maxTokensAtOnce = _count;
  }

  function setMaxTokensPerWallet(uint256 _count) public onlyOwner {
    maxTokensPerWallet = _count;
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

  function setTreasureKeys(address _keys) public onlyOwner {
    _treasureKeys = _keys;
  }

  function _baseURI() internal override view returns (string memory) {
    return __baseURI;
  }

  function setBaseURI(string memory _value) public onlyOwner {
    __baseURI = _value;
  }
}
