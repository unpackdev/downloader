//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Strings.sol";
import "./BaseControl.sol";
import "./ERC721Enumerable.sol";

// DDDB + Pellar 2022

contract DDDB is BaseControl, ERC721Enumerable {

  // variables
  uint16 public released;
  uint256 public foundingShare;

  uint16 public boundary;
  mapping(uint16 => uint16) public randoms;

  constructor() ERC721("DDDB", "DDDB") {
    _mint(0x0C94B812Df6e0c3B28F451bb0e5bF6fD0dF22451, 0);
    _mint(0x862870068d9cBfEF5E0a3903c30e0ED051bc7a22, 1);
    _mint(0x4aB7AeCFf8D75adF9f9Fa4e2E6B5204CF56aEDA3, 2);
    _mint(0x1f9d7E64480299Ab21A0aCD1dcBF854c86e58608, 3);
    _mint(0xe9B9F5B8c674064a9809204167E918c442E6aec1, 4);
    _mint(0x09E309CeC3D82A03EeDbf386342E46670Af996A8, 5);

    released = 6;
    price = 0.2 ether;
    maxSaleAmount = 500;

    boundary = MAX_SALE_SUPPLY - 6;
  }

  function mint(uint16 _amount) external payable {
    require(tx.origin == msg.sender, "Not allowed");
    require(saleActive, "Not active");
    require(_amount <= 5, "Exceed txn");
    require(balanceOf(msg.sender) + _amount <= 5, "Exceed wallet");
    require(msg.value >= _amount * price, "Incorrect ETH value");
    require(released + _amount <= maxSaleAmount, "Exceed supply");

    uint16 _boundary = boundary;
    for (uint16 i = 0; i < _amount; i++) {

      uint16 index = uint16(uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, i, totalSupply(), block.number, address(this)))) % _boundary) + 1;
      uint16 tokenId = (randoms[index] > 0 ? randoms[index] - 1 : index - 1) + 6;
      randoms[index] = randoms[_boundary] > 0 ? randoms[_boundary] : _boundary;
      _boundary -= 1;

      _safeMint(msg.sender, tokenId);
    }
    released += _amount;
    boundary = _boundary;
  }

  function burn(uint256 tokenId) external {
    require(_isApprovedOrOwner(msg.sender, tokenId), "Not allowed");
    _burn(tokenId);
  }

  /* View */
  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), "Non-exists token.");

    if (bytes(baseURI).length > 0) {
      return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }

    return unrevealedURI;
  }

  /* Admin */
  function reservation() external onlyOwner {
    for (uint16 tokenId = MAX_SALE_SUPPLY; tokenId < MAX_SUPPLY; tokenId++) {
      _mint(0x0C94B812Df6e0c3B28F451bb0e5bF6fD0dF22451, tokenId);
    }
  }

  function withdraw() external onlyOwner {
    uint256 balance = address(this).balance;
    uint256 tmpOfBalance;

    address[7] memory receivers = [
      0x862870068d9cBfEF5E0a3903c30e0ED051bc7a22,
      0x4aB7AeCFf8D75adF9f9Fa4e2E6B5204CF56aEDA3,
      0x1f9d7E64480299Ab21A0aCD1dcBF854c86e58608,
      0xe9B9F5B8c674064a9809204167E918c442E6aec1,
      0x09E309CeC3D82A03EeDbf386342E46670Af996A8,
      0xd907A8f72ecd673b011625D363e4A5bE3D95d2b2,
      0x0C94B812Df6e0c3B28F451bb0e5bF6fD0dF22451
    ];

    uint256[7] memory ratio = [
      balance * 10 / 100,
      balance * 5 / 100,
      balance * 1 / 100,
      balance * 1 / 100,
      balance * 1 / 100,
      balance * 10 / 100,
      balance * 62 / 100
    ];

    for (uint8 i = 0; i < 7; i++) {
      payable(receivers[i]).transfer(ratio[i]);
      tmpOfBalance += ratio[i];
    }

    foundingShare += (balance - tmpOfBalance);
  }

  function withdrawToFM() external onlyOwner {
    uint256 balance = foundingShare;
    foundingShare = 0;
    uint256 amount = balance / (MAX_SUPPLY - MAX_SALE_SUPPLY);
    for (uint16 tokenId = MAX_SALE_SUPPLY; tokenId < MAX_SUPPLY; tokenId++) {
      try IERC721(address(this)).ownerOf(tokenId) returns (address receiver) {
        (bool success, ) = receiver.call{value: amount}("");
        if (!success) {
          payable(msg.sender).transfer(amount);
        }
      } catch {
        payable(msg.sender).transfer(amount);
      }
    }
  }
}
