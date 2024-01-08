// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IToken {
  function bridgeMint(address to, uint amount) external returns (bool);
  function bridgeBurn(address owner, uint amount) external returns (bool);
}
