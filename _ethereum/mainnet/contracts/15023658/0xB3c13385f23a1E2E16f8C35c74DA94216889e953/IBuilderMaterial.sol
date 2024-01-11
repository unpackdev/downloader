// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBuilderMaterial {
      function spendMaterialToBuild(address owner, uint256 spend) external;
}