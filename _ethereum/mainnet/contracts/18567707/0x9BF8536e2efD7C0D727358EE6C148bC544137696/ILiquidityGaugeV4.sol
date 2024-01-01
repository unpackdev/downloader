// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.19;

struct Reward {
    address token;
    address distributor;
    uint256 period_finish;
    uint256 rate;
    uint256 last_update;
    uint256 integral;
}

interface ILiquidityGaugeV4 {
    function initialize(
        address _staking_token,
        address _admin,
        address _DFX,
        address _voting_escrow,
        address _veBoost_proxy,
        address _distributor
    ) external;

    function admin() external view returns (address _addr);

    function balanceOf(address _addr) external view returns (uint256 amount);

    function totalSupply() external view returns (uint256 amount);

    function staking_token() external view returns (address stakingToken);

    function deposit_reward_token(address _rewardToken, uint256 _amount) external;

    function deposit(uint256 _value, address _addr, bool _claim_rewards) external;

    function deposit(uint256 _value) external;

    function claim_rewards(address _addr) external;

    function claim_rewards(address _addr, address _receiver) external;

    function commit_transfer_ownership(address _addr) external;

    function accept_transfer_ownership() external;

    function name() external view returns (string memory name);

    function user_checkpoint(address _addr) external returns (bool);

    function claimable_reward(address _addr, address _reward) external view returns (uint256);

    function reward_data(address _reward) external view returns (Reward memory);

    function withdraw(uint256 _value, bool _claim_rewards) external;

    function working_balances(address _addr) external view returns (uint256);

    function working_supply() external view returns (uint256);
}
