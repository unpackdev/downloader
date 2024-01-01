// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDynamicNftFactory{
  function createDynamicNFT(
    string memory nftName,
    string memory nftSymbol
  )external returns (address clone_);

  function getImplementationContract() external view returns (address);
  function setImplementationContract(address implementationContract_) external;
}
