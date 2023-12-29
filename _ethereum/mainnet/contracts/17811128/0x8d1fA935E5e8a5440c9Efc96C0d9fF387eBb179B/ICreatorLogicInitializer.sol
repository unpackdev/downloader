// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

interface ICreatorLogicInitializer {
  function initialize(
    string memory _name,
    string memory _symbol,
    address _owner
  ) external;
}
