// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./RoleManager.sol";
import "./ModuleManager.sol";

/// @title Cyan Wallet Core Storage - A Cyan wallet's core storage.
/// @dev This contract only needed if the Module wants to access main storage of the wallet.
///     Must be the very first parent of the Module contract.
/// @author Bulgantamir Gankhuyag - <bulgaa@usecyan.com>
/// @author Naranbayar Uuganbayar - <naba@usecyan.com>
abstract contract CoreStorage is RoleManagerStorage, ModuleManagerStorage {

}
