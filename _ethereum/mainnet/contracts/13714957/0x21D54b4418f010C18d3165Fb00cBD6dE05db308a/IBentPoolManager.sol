// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./IERC20.sol";

interface IBentPoolManager {
    function feeInfo()
        external
        view
        returns (
            uint256,
            address,
            uint256,
            address,
            uint256
        );

    function rewardToken() external view returns (address);

    function mint(address user, uint256 cvxAmount) external;
}
