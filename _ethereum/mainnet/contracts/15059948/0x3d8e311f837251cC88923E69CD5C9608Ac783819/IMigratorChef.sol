// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import "./IERC20.sol";

interface IMigratorChef {
    function migrate(IERC20 token) external returns (IERC20);
}