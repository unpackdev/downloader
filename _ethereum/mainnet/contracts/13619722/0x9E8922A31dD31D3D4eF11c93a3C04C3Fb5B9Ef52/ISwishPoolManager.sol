// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./IERC20.sol";

interface ISwishPoolManager {
    struct FeeInfo {
        address bentStaker;
        uint256 bentStakerFee; // 10000 for denominator
        address cvxStaker;
        uint256 cvxStakerFee; // 10000 for denominator
    }

    function feeInfo()
        external
        view
        returns (
            address,
            uint256,
            address,
            uint256
        );

    function rewardToken() external view returns (address);

    function mint(address user, uint256 cvxAmount) external;
}
