// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";

contract OnchainBlunts is Context, ERC721Enumerable, Ownable, ReentrancyGuard {
  address internal t1 = 0x7c51d3D32825f96138905C2b91985ba0B8A1Fcc0;
  address internal t2 = 0xB284F19FFa703dAADf6745d3C655F309D17370a5;
  address internal t3 = 0xB78F471f963B492Fe0Fe887d0D41eB524c10883E;

  string private _baseTokenURI;

  bool private _isSaleActive = false;

  uint public constant BLUNT_PRICE = 20000000000000000; // 0.02 eth
  uint public constant MAX_BLUNT_SUPPLY = 1000;
  uint public promoTokens = 35;

  constructor(string memory name, string memory symbol, string memory baseTokenURI) ERC721(name, symbol) {
    _baseTokenURI = baseTokenURI;
  }

  function mintBlunt(uint _count) external payable nonReentrant() {
    require(_isSaleActive == true, "Sale must be active");
    require(totalSupply() < MAX_BLUNT_SUPPLY, "No more Blunts");
    require(_count > 0 && _count <= 20, "Must mint from 1 to 20 Blunts");
    require(_count <= MAX_BLUNT_SUPPLY - totalSupply(), "Not enough Blunts left to mint");
    require(msg.value >= _price(_count), "Value below price");

    uint i;
    uint id;

    for(i = 0; i < _count; i++){
      id = totalSupply() + 1;
      _safeMint(msg.sender, id);
    }
  }

function mintPromo(uint _count) external onlyOwner {
    require(_isSaleActive == false, "Sale has started");
    require(promoTokens > 0, "0 promos left to mint");

    uint i;
    uint id;

    for(i = 0; i < _count; i++){
      if (promoTokens > 0) {
        id = totalSupply() + 1;
        _safeMint(owner(), id);
        promoTokens--;
      }
    }
  }

  function _price(uint _count) internal pure returns (uint256) {
    return BLUNT_PRICE * _count;
  }

  function withdrawAll() external payable {
    uint256 balance = address(this).balance;
    require(balance > 0,  "Empty balance");
    _withdraw(t1, (balance * 40) / 100);
    _withdraw(t2, (balance * 40) / 100);
    _withdraw(t3, (balance * 20) / 100);
  }

  function hasSaleStarted() external view returns (bool) {
    return _isSaleActive;
  }

  function _withdraw(address _address, uint256 _amount) private {
    (bool success, ) = _address.call{value: _amount}("");
    require(success, "Transfer failed");
  }

  function toggleSale() external onlyOwner {
    _isSaleActive = !_isSaleActive;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function tokenURI(uint tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "This Blunt does not exist");

    return string(abi.encodePacked(_baseTokenURI, uintToBytes(tokenId), ".json"));
  }

  function uintToBytes(uint v) private pure returns (bytes32 ret) {
    if (v == 0) {
      ret = '0';
    }
    else {
      while (v > 0) {
        ret = bytes32(uint(ret) / (2 ** 8));
        ret |= bytes32(((v % 10) + 48) * 2 ** (8 * 31));
        v /= 10;
      }
    }
    return ret;
  }
}
