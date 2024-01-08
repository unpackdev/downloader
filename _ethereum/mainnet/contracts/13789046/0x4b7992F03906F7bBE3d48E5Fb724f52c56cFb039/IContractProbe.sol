// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IContractProbe {
  function probe(address _address) external view returns (bool isContract, address forwardedTo);
}
