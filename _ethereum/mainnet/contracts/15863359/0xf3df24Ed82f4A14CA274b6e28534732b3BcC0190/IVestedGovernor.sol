// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    security-contact:
    - marcin@angelblock.io
    - piotr@angelblock.io
    - mikolaj@angelblock.io

**************************************/

import "./IGovernorTimelock.sol";

/**************************************

    VestedGovernor interface

 **************************************/

abstract contract IVestedGovernor is IGovernorTimelock {}
