pragma solidity 0.8.9;

import "./StringHex.sol";

library BridgeInLibrary {
  using StringHex for bytes32;

  function _generateTokenKey(address token, string memory chainId) public pure returns (bytes32) {
    return sha256(abi.encodePacked(token, chainId));
  }

  function _generateReceiptId(
    bytes32 tokenKey,
    string memory suffix
  ) public pure returns (string memory) {
    string memory prefix = tokenKey.toHex();
    string memory separator = '.';
    return string(abi.encodePacked(prefix, separator, suffix));
  }
}
