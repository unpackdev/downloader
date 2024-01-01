// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "./IInitializable.sol";
import "./InitializableInternal.sol";

abstract contract Initializable is IInitializable, InitializableInternal {}
