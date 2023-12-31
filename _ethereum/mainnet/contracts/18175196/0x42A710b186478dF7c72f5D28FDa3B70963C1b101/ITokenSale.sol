// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface ITokenSale {
  function shares(address account) external returns (uint256 share);
}
