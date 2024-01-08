// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.6;

import "./IERC20.sol";

interface I1MIL is IERC20 {
    function INITIAL_SUPPLY() external view returns (uint);
    function MAX_SUPPLY() external view returns (uint);
}
