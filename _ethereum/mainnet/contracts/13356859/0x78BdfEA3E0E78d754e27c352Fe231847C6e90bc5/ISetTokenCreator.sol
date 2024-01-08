// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.7.6;

interface ISetTokenCreator {
  /*
   * init new set token with params.
   */
  function create(
    address[] memory _components,
    int256[] memory _units,
    address[] memory _modules,
    address _manager,
    string memory _name,
    string memory _symbol
  ) external returns (address);
}
