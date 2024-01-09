// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "./IERC20.sol";

interface IwTROVE is IERC20 {
    function wrap(uint _amount) external returns (uint);

    function unwrap(uint _amount) external returns (uint);
}