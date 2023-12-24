// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "./IERC173.sol";
import "./IOwnableInternal.sol";

interface IOwnable is IOwnableInternal, IERC173 {}
