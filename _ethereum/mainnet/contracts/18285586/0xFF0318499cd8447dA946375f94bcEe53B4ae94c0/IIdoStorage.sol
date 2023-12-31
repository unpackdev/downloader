// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;


import "./IIdoStorageActions.sol";
import "./IIdoStorageErrors.sol";
import "./IIdoStorageEvents.sol";
import "./IIdoStorageState.sol";


interface IIdoStorage is IIdoStorageState, IIdoStorageActions, IIdoStorageEvents, IIdoStorageErrors  {
}