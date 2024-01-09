// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Governable.sol";
import "./Manageable.sol";

interface IGovernableAndManageable is IManageable, IGovernable {}
