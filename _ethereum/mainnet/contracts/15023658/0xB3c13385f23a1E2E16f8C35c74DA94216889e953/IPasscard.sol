// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPasscard {
      function qualified(address owner, uint256 buildType) external returns(bool);
}