// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";

interface LootInterface {
  function ownerOf(uint256 tokenId) external view returns (address owner);
}

interface TemporalLootInterface {
  function ownerOf(uint256 tokenId) external view returns (address owner);
}

interface SVBLootInterface {
  function ownerOf(uint256 tokenId) external view returns (address owner);
}

contract RawLoot is ERC721Enumerable, ReentrancyGuard, Ownable {
  using SafeMath for uint256;

  bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

  // Set public price
  uint256 private constant PUBLIC_PRICE = 5000000000000000; //0.005 ETH

  // Random limit
  uint256 private constant RANDOM_LIMIT = 50000;

  // Bag of RawMaterials
  mapping(uint256 =>  uint256[7]) private bagOfRawMaterials;

  // Interfaces
  LootInterface public lootContract = LootInterface(0xFF9C1b15B16263C61d017ee9F65C50e4AE0113D7);
  TemporalLootInterface public temporalLootContract = TemporalLootInterface(0x1dfe7Ca09e99d10835Bf73044a23B73Fc20623DF);
  SVBLootInterface public SVBLootContract = SVBLootInterface(0x471E9CfcfB031B71813F0F7530696f41c09c4a9c);

  event MintedPublic(uint256 tokenId, uint256[7] items);
  event MintedWithLoot(uint256 lootId, uint256 tokenId, uint256[7] items);

  // Mint for loot holders
  function publicMint(uint256 tokenId) external payable nonReentrant {
    require(msg.value >= PUBLIC_PRICE , "Eth sent must be .005");
    require(tokenId >= 75000 && tokenId < block.number.div(100), "Token Id must between 50000 and the latest block divided by 100");

    bagOfRawMaterials[tokenId][0] = _random(tokenId);
    bagOfRawMaterials[tokenId][1] = _random(bagOfRawMaterials[tokenId][0]);
    bagOfRawMaterials[tokenId][2] = _random(bagOfRawMaterials[tokenId][1]);
    bagOfRawMaterials[tokenId][3] = _random(bagOfRawMaterials[tokenId][2]);
    bagOfRawMaterials[tokenId][4] = _random(bagOfRawMaterials[tokenId][3]);
    bagOfRawMaterials[tokenId][5] = _random(bagOfRawMaterials[tokenId][4]);
    bagOfRawMaterials[tokenId][6] = _random(bagOfRawMaterials[tokenId][5]);

    emit MintedPublic(tokenId, bagOfRawMaterials[tokenId]);

    _safeMint(_msgSender(), tokenId);
  }

  function mintWithLoot(uint256 lootId, uint256 tokenId) external nonReentrant {
    require(lootContract.ownerOf(lootId) == msg.sender || temporalLootContract.ownerOf(lootId) == msg.sender || SVBLootContract.ownerOf(lootId) == msg.sender, "You must own Loot, TemporalLoot, or SVBLootContract");

    require(tokenId >= 0 && tokenId < 75000, "Token Id must between 0 and 75000");

    bagOfRawMaterials[tokenId][0] = _random(tokenId);
    bagOfRawMaterials[tokenId][1] = _random(bagOfRawMaterials[tokenId][0]);
    bagOfRawMaterials[tokenId][2] = _random(bagOfRawMaterials[tokenId][1]);
    bagOfRawMaterials[tokenId][3] = _random(bagOfRawMaterials[tokenId][2]);
    bagOfRawMaterials[tokenId][4] = _random(bagOfRawMaterials[tokenId][3]);
    bagOfRawMaterials[tokenId][5] = _random(bagOfRawMaterials[tokenId][4]);
    bagOfRawMaterials[tokenId][6] = _random(bagOfRawMaterials[tokenId][5]);

    emit MintedWithLoot(lootId, tokenId, bagOfRawMaterials[tokenId]);

    _safeMint(_msgSender(), tokenId);
  }

  function getBagOfRawMaterials(uint256 tokenId) public view returns(uint256[7] memory) {
    return bagOfRawMaterials[tokenId];
  }
  
  // Withdraw for owner
  function withdraw() external onlyOwner {
    payable(0x17565EAb834087ac27fCbe76F9CD7006F185F014).transfer(address(this).balance);
  }
  
  function _random(uint256 salt) private view returns (uint256) {
    uint256 num = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, salt))) % RANDOM_LIMIT;

    if(num == 0) {
      return 1;
    }

    return num;
  }

  function _toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

    if (value == 0) {
      return "0";
    }
    uint256 temp = value;
    uint256 digits;
    while (temp != 0) {
      digits++;
      temp /= 10;
    }
    bytes memory buffer = new bytes(digits);
    while (value != 0) {
      digits -= 1;
      buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
      value /= 10;
    }
    return string(buffer);
  }

  function _encode(bytes memory data) public pure returns (string memory) {
    uint256 len = data.length;
    if (len == 0) return "";

    // multiply by 4/3 rounded up
    uint256 encodedLen = 4 * ((len + 2) / 3);

    // Add some extra buffer at the end
    bytes memory result = new bytes(encodedLen + 32);

    bytes memory table = TABLE;

    assembly {
      let tablePtr := add(table, 1)
      let resultPtr := add(result, 32)

      for {
        let i := 0
      } lt(i, len) {

      } {
        i := add(i, 3)
        let input := and(mload(add(data, i)), 0xffffff)

        let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
        out := shl(8, out)
        out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
        out := shl(8, out)
        out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
        out := shl(8, out)
        out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
        out := shl(224, out)

        mstore(resultPtr, out)

        resultPtr := add(resultPtr, 4)
      }

      switch mod(len, 3)
        case 1 {
          mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
        }
        case 2 {
          mstore(sub(resultPtr, 1), shl(248, 0x3d))
        }

      mstore(result, encodedLen)
    }

    return string(result);
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    string[16] memory parts;
    parts[
      0
    ] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';

    parts[1] = _toString(bagOfRawMaterials[tokenId][0]);
    parts[2] = '</text><text x="10" y="40" class="base">';
    parts[3] = _toString(bagOfRawMaterials[tokenId][1]);
    parts[4] = '</text><text x="10" y="60" class="base">';
    parts[5] = _toString(bagOfRawMaterials[tokenId][2]);
    parts[6] = '</text><text x="10" y="80" class="base">';
    parts[7] = _toString(bagOfRawMaterials[tokenId][3]);
    parts[8] = '</text><text x="10" y="100" class="base">';
    parts[9] = _toString(bagOfRawMaterials[tokenId][4]);
    parts[10] = '</text><text x="10" y="120" class="base">';
    parts[11] = _toString(bagOfRawMaterials[tokenId][5]);
    parts[12] = '</text><text x="10" y="140" class="base">';
    parts[13] = _toString(bagOfRawMaterials[tokenId][6]);
    parts[14] = "</text></svg>";

    string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));
    output = string(abi.encodePacked(output, parts[9], parts[10], parts[11], parts[12], parts[13], parts[14]));

    string memory json =
      _encode(
        bytes(
          string(
            abi.encodePacked(
              '{"name": "RawLoot #',
              _toString(tokenId),
              '", "description": "RawLoot: Materials to create ForgedLoot and other derivatives based off RawLoot.", "image": "data:image/svg+xml;base64,',
              _encode(bytes(output)),
              '"}'
            )
          )
        )
      );

    output = string(abi.encodePacked("data:application/json;base64,", json));

    return output;
  }

  constructor() ERC721("RawLoot", "RWLT") Ownable() {}
}