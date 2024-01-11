// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "./IERC20.sol";

interface IWarmup is IERC20 {
    function retrieve( address staker_, uint amount_ ) external;
}
