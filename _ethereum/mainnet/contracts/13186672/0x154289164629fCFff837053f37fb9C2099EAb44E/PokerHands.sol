// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./console.sol";

contract PokerHands is ERC721Enumerable, ReentrancyGuard, Ownable {
  string[] private deck = [
    "Ace of Spades",
    "King of Spades",
    "Queen of Spades",
    "Jack of Spades",
    "Ten of Spades",
    "Nine of Spades",
    "Eight of Spades",
    "Seven of Spades",
    "Six of Spades",
    "Five of Spades",
    "Four of Spades",
    "Three of Spades",
    "Two of Spades",
    "Ace of Hearts",
    "King of Hearts",
    "Queen of Hearts",
    "Jack of Hearts",
    "Ten of Hearts",
    "Nine of Hearts",
    "Eight of Hearts",
    "Seven of Hearts",
    "Six of Hearts",
    "Five of Hearts",
    "Four of Hearts",
    "Three of Hearts",
    "Two of Hearts",
    "Ace of Diamonds",
    "King of Diamonds",
    "Queen of Diamonds",
    "Jack of Diamonds",
    "Ten of Diamonds",
    "Nine of Diamonds",
    "Eight of Diamonds",
    "Seven of Diamonds",
    "Six of Diamonds",
    "Five of Diamonds",
    "Four of Diamonds",
    "Three of Diamonds",
    "Two of Diamonds",
    "Ace of Clubs",
    "King of Clubs",
    "Queen of Clubs",
    "Jack of Clubs",
    "Ten of Clubs",
    "Nine of Clubs",
    "Eight of Clubs",
    "Seven of Clubs",
    "Six of Clubs",
    "Five of Clubs",
    "Four of Clubs",
    "Three of Clubs",
    "Two of Clubs"
  ];

  function random(string memory input) internal pure returns (uint256) {
    return uint256(keccak256(abi.encodePacked(input)));
  }

  function getHand(uint256 tokenId) internal view returns (string[] memory) {
    for (uint256 attempt = 1; attempt < 100; attempt++) {
      string[] memory ret = generateHand(tokenId, attempt);
      if (hasDuplicates(ret)) {
        continue;
      }
      findJokers(tokenId, ret);
      return ret;
    }
    require(false, "Unable to generate hand.");
    return new string[](0);
  }

  function findJokers(uint256 tokenId, string[] memory hand) internal pure {
    uint256 n = random(
      string(abi.encodePacked("findJokers", toString(tokenId)))
    ) % 10000;

    if (n < 10) {
      hand[randomIndex(tokenId, "redJoker")] = "Red Joker";
      hand[randomIndex(tokenId, "blackJoker")] = "Black Joker";
    } else if (n <= 110) {
      hand[randomIndex(tokenId, "redJoker")] = "Red Joker";
    } else if (n <= 210) {
      hand[randomIndex(tokenId, "blackJoker")] = "Black Joker";
    }
  }

  function randomIndex(uint256 tokenId, string memory key)
    internal
    pure
    returns (uint256)
  {
    return random(string(abi.encodePacked(key, toString(tokenId)))) % 5;
  }

  function hasDuplicates(string[] memory hand) internal pure returns (bool) {
    for (uint256 i = 0; i < 5; i++) {
      for (uint256 j = i + 1; j < 5; j++) {
        if (stringEquals(hand[i], hand[j])) {
          return true;
        }
      }
    }
    return false;
  }

  function stringEquals(string memory a, string memory b)
    internal
    pure
    returns (bool)
  {
    bytes memory aa = bytes(a);
    bytes memory bb = bytes(b);
    if (aa.length != bb.length) {
      return false;
    } else {
      return keccak256(aa) == keccak256(bb);
    }
  }

  function generateHand(uint256 tokenId, uint256 attempt)
    internal
    view
    returns (string[] memory)
  {
    string memory tokenString = toString(tokenId);
    string[] memory ret = new string[](5);

    for (uint256 i = 0; i < 5; i++) {
      uint256 rand = random(
        string(abi.encodePacked(toString(attempt), toString(i), tokenString))
      );
      ret[i] = deck[rand % deck.length];
    }

    return ret;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override
    returns (string memory)
  {
    string[] memory hand = getHand(tokenId);
    string[17] memory parts;
    parts[
      0
    ] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';

    parts[1] = hand[0];
    parts[2] = '</text><text x="10" y="40" class="base">';
    parts[3] = hand[1];
    parts[4] = '</text><text x="10" y="60" class="base">';
    parts[5] = hand[2];
    parts[6] = '</text><text x="10" y="80" class="base">';
    parts[7] = hand[3];
    parts[8] = '</text><text x="10" y="100" class="base">';
    parts[9] = hand[4];
    parts[10] = "</text></svg>";

    string memory output = string(
      abi.encodePacked(
        parts[0],
        parts[1],
        parts[2],
        parts[3],
        parts[4],
        parts[5],
        parts[6],
        parts[7],
        parts[8]
      )
    );
    output = string(abi.encodePacked(output, parts[9], parts[10]));

    string memory json = Base64.encode(
      bytes(
        string(
          abi.encodePacked(
            '{"name": "Hand #',
            toString(tokenId),
            '", "description": "Randomly generated poker hands generated and stored on chain. Feel free to use PokerHands in any way you want.", "image": "data:image/svg+xml;base64,',
            Base64.encode(bytes(output)),
            '"}'
          )
        )
      )
    );
    output = string(abi.encodePacked("data:application/json;base64,", json));

    return output;
  }

  // 10,000 total tokens, 10 reserved
  function claim(uint256 tokenId) public nonReentrant {
    require(tokenId > 0 && tokenId < 9990, "Token ID invalid");
    _safeMint(_msgSender(), tokenId);
  }

  function ownerClaim(uint256 tokenId) public nonReentrant onlyOwner {
    require(tokenId >= 9991 && tokenId <= 10000, "Token ID invalid");
    _safeMint(owner(), tokenId);
  }

  function toString(uint256 value) internal pure returns (string memory) {
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

  constructor() ERC721("PokerHands", "POKERHANDS") Ownable() {}
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <brecht@loopring.org>
library Base64 {
  bytes internal constant TABLE =
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

  /// @notice Encodes some bytes to the base64 representation
  function encode(bytes memory data) internal pure returns (string memory) {
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
        out := add(
          out,
          and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
        )
        out := shl(8, out)
        out := add(
          out,
          and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
        )
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
}
