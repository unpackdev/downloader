// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

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


interface Church {
  function cardinal() external view returns (address);
}

contract Metadata2 {
  using Strings for uint256;

  Church public church = Church(0x688025e03Dc3359E07773ADC923e01aeC9Af96A1);
  string public baseURI = 'ipfs://QmWkGohobRy75Kqmp2tNsvrrNn4DLjNJtgMqPBjFnUPzMx/';

  function tokenURI(uint256 tokenId) external view returns (string memory) {
    return string(abi.encodePacked(baseURI, tokenId.toString(), '.json'));
  }

  function updateBaseURI(string calldata newURI) external {
    require(
      msg.sender == church.cardinal()
      || msg.sender == address(church)
    );
    baseURI = newURI;
  }
}