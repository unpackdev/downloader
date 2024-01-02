// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.21;

import "./ITokenizedStrategy.sol";
import "./IBaseStrategy.sol";

interface IStrategy is IBaseStrategy, ITokenizedStrategy {}
