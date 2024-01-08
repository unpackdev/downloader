// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IBancorContractRegistry {
  function addressOf(
      bytes32 contractName
  ) external returns(address);
}
