// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IVersusBattle {
  function contest(uint256[] memory hostHeroes, uint256[] memory clientHeroes)
    external
    view
    returns (uint256);
}
