//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";

import "./CIPSwap.sol";

abstract contract CIPStaking is OwnableUpgradeable, CIPSwap {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using MathUpgradeable for uint256;

    uint256 public reward_rate;
    uint256 public reward_per_token_stored;
    uint256 public last_time_updated;
    mapping(address => uint256) public paid;
    mapping(address => uint256) public rewards;

    function initialize() public virtual override initializer {
        super.initialize();
        __Ownable_init_unchained();
    }

    function claim_reward() public {
        sync_reward();
        sync_account(msg.sender);
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            address collar = address_collar();
            IERC20Upgradeable(collar).safeTransfer(msg.sender, reward);
        }
    }

    function start_reward(uint256 rate) external onlyOwner {
        sync_reward();
        reward_rate = rate;
    }

    function reward_per_token() public view returns (uint256) {
        uint256 ts = totalSupply();

        if (ts == 0) {
            return reward_per_token_stored;
        }

        uint256 time = reward_end().min(block.timestamp);
        time -= last_time_updated;
        return (time * reward_rate * 1e18) / ts + reward_per_token_stored;
    }

    function earned(address account) public view returns (uint256) {
        uint256 result = balanceOf(account);
        uint256 reward = reward_per_token() - paid[account];
        return (result * reward) / 1e18 + rewards[account];
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256
    ) internal override {
        sync_reward();
        if (from != address(0)) {
            sync_account(from);
        }
        if (to != address(0)) {
            sync_account(to);
        }
    }

    function sync_reward() internal {
        reward_per_token_stored = reward_per_token();
        last_time_updated = reward_end().min(block.timestamp);
    }

    function sync_account(address account) internal {
        rewards[account] = earned(account);
        paid[account] = reward_per_token_stored;
    }

    function reward_end() public pure virtual returns (uint256) {
        return 2008000000;
    }
}
