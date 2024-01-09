// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

interface IMinter {
  function safeMint(address to, string memory uri) external;
}
