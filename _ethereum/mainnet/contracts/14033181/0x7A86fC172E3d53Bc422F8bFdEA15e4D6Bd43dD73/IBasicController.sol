// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

interface IBasicController {
  function registerSubdomainExtended(
    uint256 parentId,
    string memory label,
    address owner,
    string memory metadata,
    uint256 royaltyAmount,
    bool lockOnCreation
  ) external returns (uint256);
}
