// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;


interface IStakingRewards {
    // Views

    function rewardPerToken() external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    // Mutative

    function stakeWithPermit(uint256 amount, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    function stake(uint256 amount) external;

    function stakeTo(uint256 amount, address to) external;

    function withdraw(uint256 amount) external;

    function getReward() external;

    function exit() external;
}

interface IUniswapV2ERC20 {
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}

