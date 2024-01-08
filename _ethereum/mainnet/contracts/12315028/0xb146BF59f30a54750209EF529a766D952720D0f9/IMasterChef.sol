//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./SafeERC20.sol";

interface IMasterChef {
    using SafeERC20 for IERC20;

    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. SUSHI to distribute per block.
        uint256 lastRewardBlock; // Last block number that SUSHI distribution occurs.
        uint256 accSushiPerShare; // Accumulated SUSHI per share, times 1e12. See below.
    }

    function userInfo(uint256, address)
        external
        view
        returns (uint256 amount, uint256 rewardDebt);

    function poolInfo(uint256 pid) external view returns (PoolInfo memory);

    function totalAllocPoint() external view returns (uint256);

    function deposit(uint256 _pid, uint256 _amount) external;
}
