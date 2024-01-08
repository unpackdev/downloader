// SPDX-License-Identifier: MIT
pragma solidity 0.6.10;

import {IERC20} from "IERC20.sol";

import {ITrueDistributor} from "ITrueDistributor.sol";

interface ITrueMultiFarm {
    function trueDistributor() external view returns (ITrueDistributor);

    function stake(IERC20 token, uint256 amount) external;

    function unstake(IERC20 token, uint256 amount) external;

    function claim(IERC20[] calldata tokens) external;

    function exit(IERC20[] calldata tokens) external;
}
