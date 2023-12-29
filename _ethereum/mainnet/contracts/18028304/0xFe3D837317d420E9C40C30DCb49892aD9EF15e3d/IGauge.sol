// SPDX-License-Identifier: UNLICENSED
// solhint-disable-next-line compiler-version
pragma solidity >=0.8.0;

import "./IERC20.sol";

// solhint-disable func-name-mixedcase
interface IGauge is IERC20 {
    // solhint-disable var-name-mixedcase
    struct Reward {
        address distributor;
        uint256 period_finish;
        uint256 rate;
        uint256 last_update;
        uint256 integral;
    }

    function initialize(
        address stakingToken,
        address admin,
        address reward,
        address ve,
        address veBoost,
        address distributor
    ) external;

    function deposit(uint256 value, address addr) external;

    function withdraw(uint256 value) external;

    function add_reward(address token, address distributor) external;

    function set_reward_distributor(address token, address distributor)
        external;

    function user_checkpoint(address addr) external returns (bool);

    function claim_rewards(address addr) external;

    function deposit_reward_token(address, uint256) external;

    function commit_transfer_ownership(address) external;

    function accept_transfer_ownership() external;

    function admin() external view returns (address);

    function future_admin() external view returns (address);

    function claimable_reward(address addr, address token)
        external
        view
        returns (uint256);

    function claimed_reward(address addr, address token)
        external
        view
        returns (uint256);

    function reward_count() external view returns (uint256);

    function reward_tokens(uint256 index) external view returns (address);

    function reward_data(address) external view returns (Reward memory);

    function staking_token() external view returns (address);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}
