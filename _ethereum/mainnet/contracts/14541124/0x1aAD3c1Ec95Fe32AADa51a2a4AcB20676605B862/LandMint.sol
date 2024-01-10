// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./ERC1155.sol";
import "./ERC721Enumerable.sol";

import "./Admin.sol";

abstract contract LandMint is AdminOwnable, ERC721Enumerable {
  struct MintData {
    int8 x0;
    int8 x1;
    int8 y0;
    int8 y1;
    uint32 prevMintCount;
    uint32 blockNumber;
    address addr;
    uint256 value;
  }

  uint16 private _maximumLand;
  mapping(address => uint32) private _addressMintCount;
  
  constructor(uint16 maximumLand) {
    _maximumLand = maximumLand;
  }

  function prevMintCount(address addr) external view returns (uint32) {
    return _addressMintCount[addr];
  }

  function _mintLand(
    MintData calldata mintData,
    bytes calldata signature
  ) internal returns (uint256[] memory) {

    require(verifyAdminSignature(keccak256(abi.encode(mintData)), signature), "Invalid Signature");
    require(mintData.addr == _msgSender(), "Incorrect address");
    require(mintData.x1 >= mintData.x0, "Invalid X range");
    require(mintData.y1 >= mintData.y0, "Invalid Y range");
    require(block.number <= mintData.blockNumber, "Invalid block Number");
    require(msg.value >= mintData.value, "Not enough value");
    require(_addressMintCount[_msgSender()] == mintData.prevMintCount, "prevMintCount does not match");

    uint8 width = uint8(mintData.x1 - mintData.x0 + 1);
    uint8 height = uint8(mintData.y1 - mintData.y0 + 1);
    uint256 size = uint256(width) * uint256(height);
    
    require(_maximumLand >= super.totalSupply() + size, "Total land supply overflow!");
 
    uint256[] memory tokens = new uint256[](size);
    uint32 index = 0;
    for (int32 x = mintData.x0; x <= mintData.x1; x++) {
      for (int32 y = mintData.y0; y <= mintData.y1; y++) {
        uint256 tokenId = uint256(uint32(x)) | uint256(uint32(y) << 7);
        tokens[index] = tokenId;
        index++;
      }
    }
    
    _addressMintCount[_msgSender()] += index;

    return tokens;
  }
}