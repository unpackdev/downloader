// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

interface IMushroomFactory  {
    function costPerMushroom() external returns (uint256);
    function getRemainingMintableForMySpecies(uint256 numMushrooms) external view returns (uint256);
    function growMushrooms(address recipient, uint256 numMushrooms) external;
}