// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface ITextResolver {
  event TextChanged(
    bytes32 indexed node,
    string indexed indexedKey,
    string key,
    string value
  );

  function text(
    bytes32 node,
    string calldata key
  ) external view returns (string memory);
}
