// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;
pragma experimental ABIEncoderV2;

import "./ERC721Enumerable.sol";

contract GMNFT is ERC721Enumerable {
  // GM count per address
  mapping(address => uint256) public gms;

  // Total GM count
  uint256 public gmTotal;

  // Latest person to send gm
  address public latestGM;

  // gm variations
  bytes32 constant GM_HASH = keccak256(abi.encodePacked("GM"));
  bytes32 constant Gm_HASH = keccak256(abi.encodePacked("Gm"));
  bytes32 constant gm_HASH = keccak256(abi.encodePacked("gm"));
  bytes32 constant gM_HASH = keccak256(abi.encodePacked("gM"));

  constructor() ERC721("good morning", "gm") {}

  // gm
  event gm(address indexed sender, uint256 indexed gmTotal, uint256 indexed senderGMTotal);

  function claim() external {
    _safeMint(_msgSender(), totalSupply());
  }

  function sayGM(string memory input) external {
    bytes32 inputHash = keccak256(abi.encodePacked(input));
    require(inputHash == GM_HASH || inputHash == Gm_HASH || inputHash == gm_HASH || inputHash == gM_HASH, "Not gm");
    require(latestGM != _msgSender(), "Cannot be the last person who gm'd");
    latestGM = _msgSender();
    gms[_msgSender()]++;
    gmTotal++;

    emit gm(_msgSender(), gmTotal, gms[_msgSender()]);
  }

  function tokenURI(uint256 tokenId) override public view returns (string memory) {
    address owner = ownerOf(tokenId);
    uint256 count = gms[owner];

    string[5] memory parts;

    parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 360 360"><style>.base { fill: white; font-family: serif; font-size: 64px; }</style><rect width="100%" height="100%" fill="black" rx="180" /><text x="50%" y="170" class="base" text-anchor="middle">';

    // most recent GM gets a special sun smiley
    if (latestGM == owner) {
      parts[1] = unicode"🌞";
    } else {
      parts[1] = "gm";
    }

    parts[2] ='</text><text x="50%" y="230" class="base" text-anchor="middle">';

    parts[3] = toString(count);

    parts[4] = '</text></svg>';

    string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4]));

    string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "gm #', toString(tokenId), '", "description": "Good morning badge with your gm count by address stored onchain.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
    output = string(abi.encodePacked('data:application/json;base64,', json));

    return output;
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
}

/// @title Base64
/// @author Brecht Devos - <brecht@loopring.org>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
               dataPtr := add(dataPtr, 3)

               // read 3 bytes
               let input := mload(dataPtr)

               // write 4 characters
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
               resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }
}
