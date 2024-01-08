//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;


interface IContractRegistry {
  function addressOf(bytes32 contractName) external view returns(address);
}