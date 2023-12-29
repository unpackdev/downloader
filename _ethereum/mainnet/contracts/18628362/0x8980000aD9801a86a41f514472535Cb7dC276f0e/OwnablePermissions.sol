// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Context.sol";

abstract contract OwnablePermissions is Context {
    function _requireCallerIsContractOwner() internal view virtual;
}
