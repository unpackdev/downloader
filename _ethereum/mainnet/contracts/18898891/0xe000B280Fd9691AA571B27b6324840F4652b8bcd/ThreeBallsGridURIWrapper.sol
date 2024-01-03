// SPDX-License-Identifier: CC0


/*
████████ ██   ██ ██████  ███████ ███████
   ██    ██   ██ ██   ██ ██      ██
   ██    ███████ ██████  █████   █████
   ██    ██   ██ ██   ██ ██      ██
   ██    ██   ██ ██   ██ ███████ ███████


██████   █████  ██      ██      ███████
██   ██ ██   ██ ██      ██      ██
██████  ███████ ██      ██      ███████
██   ██ ██   ██ ██      ██           ██
██████  ██   ██ ███████ ███████ ███████


 ██████  ██████  ██ ██████
██       ██   ██ ██ ██   ██
██   ███ ██████  ██ ██   ██
██    ██ ██   ██ ██ ██   ██
 ██████  ██   ██ ██ ██████



CC0 2023 - steviep.eth
*/


pragma solidity ^0.8.23;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
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
}



interface IThreeBallsGridURI {
  function description() external view returns (string memory);
  function license() external view returns (string memory);
  function externalUrl() external view returns (string memory);
  function attrs(uint256 tokenId) external view returns (bytes memory);
  function encodedSVG(uint256 tokenId) external view returns (string memory);
}



contract ThreeBallsGridURIWrapper {
  using Strings for uint256;
  IThreeBallsGridURI public uri = IThreeBallsGridURI(0xEF769168ef13903Ded12AdF9972C2F5D5f715Bf5);

  function tokenURI(uint256 tokenId) external view returns (string memory) {
    bytes memory json = abi.encodePacked(
      'data:application/json;utf8,',
      '{"name": "Three Balls Grid #', tokenId.toString(),'",'
      '"description": "', uri.description(), '",'
      '"license": "', uri.license(), '",'
      '"external_url": "', uri.externalUrl(), '",'
      '"attributes": ', uri.attrs(tokenId),','
      '"image": "', uri.encodedSVG(tokenId),
      '"}'
    );
    return string(json);
  }
}