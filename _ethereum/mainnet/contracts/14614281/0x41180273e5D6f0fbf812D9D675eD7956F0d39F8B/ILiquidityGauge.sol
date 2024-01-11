// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

interface ILiquidityGauge {
    // solhint-disable-next-line
    function staking_token() external returns (address stakingToken);

    // solhint-disable-next-line
    function set_staking_token_and_scaling_factor(address token, uint256 value) external;

    // solhint-disable-next-line
    function recover_erc20(
        address token,
        address addr,
        uint256 amount
    ) external;

    // solhint-disable-next-line
    function commit_transfer_ownership(address addr) external;

    // solhint-disable-next-line
    function accept_transfer_ownership() external;

    // solhint-disable-next-line
    function deposit_reward_token(address _rewardToken, uint256 _amount) external;

    function deposit(
        uint256 _value,
        address _addr,
        // solhint-disable-next-line
        bool _claim_rewards
    ) external;

    // solhint-disable-next-line
    function claim_rewards(address _addr) external;

    // solhint-disable-next-line
    function claim_rewards(address _addr, address _receiver) external;
}
