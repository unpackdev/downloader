//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

library EncodeLibrary {
  string internal constant TABLE =
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

  function encode(bytes memory data) internal pure returns (string memory) {
    if (data.length == 0) return "";

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
      for {

      } lt(dataPtr, endPtr) {

      } {
        dataPtr := add(dataPtr, 3)

        // read 3 bytes
        let input := mload(dataPtr)

        // write 4 characters
        mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
        resultPtr := add(resultPtr, 1)
        mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
        resultPtr := add(resultPtr, 1)
        mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F)))))
        resultPtr := add(resultPtr, 1)
        mstore(resultPtr, shl(248, mload(add(tablePtr, and(input, 0x3F)))))
        resultPtr := add(resultPtr, 1)
      }

      // padding with '='
      switch mod(mload(data), 3)
      case 1 {
        mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
      }
      case 2 {
        mstore(sub(resultPtr, 1), shl(248, 0x3d))
      }
    }

    return result;
  }

  function toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT licence
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

  function makeTrait(string memory name, string memory value)
    internal
    pure
    returns (string memory)
  {
    return string(abi.encodePacked('{ "trait_type": "', name, '", "value": "', value, '" }'));
  }

  function makeNumberTrait(string memory name, uint256 value)
    internal
    pure
    returns (string memory)
  {
    return
      string(
        abi.encodePacked(
          '{ "display_type": "number", "trait_type": "',
          name,
          '", "value": "',
          toString(value),
          '" }'
        )
      );
  }
}
