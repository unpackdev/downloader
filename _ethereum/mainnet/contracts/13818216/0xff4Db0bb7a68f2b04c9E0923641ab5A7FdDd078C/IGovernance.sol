// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IGovernance {
  // from the docs?
  function registerFactory(address creator, bytes calldata signature) external;

  // from the codebase (master branch)?
  function registerNFTFactoryCreator(uint32 _creatorAccountId, address creator, bytes calldata signature) external;
}
