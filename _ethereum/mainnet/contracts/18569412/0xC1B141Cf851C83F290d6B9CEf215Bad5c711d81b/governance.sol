// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./SafeERC20.sol";

import "./gov_getters.sol";
import "./gov_setters.sol";
import "./i_gov_token.sol";
import "./i_sgov_token.sol";

contract Governance is Initializable, UUPSUpgradeable, ReentrancyGuardUpgradeable, Gov_Getters, Gov_Setters {
	/// @custom:oz-upgrades-unsafe-allow constructor
	constructor() {
		_disableInitializers();
	}

	event Stake(address from, uint256 amount);
	event Unstake(address from, uint256 amount);
	event Claim_Rewards(address to, uint256 amount);
	event Transfer_Stake(address from, address to, uint256 amount);

	function initialize(address gov_token, address sgov_token) public initializer {
		__Ownable_init();
		__UUPSUpgradeable_init();
		__ReentrancyGuard_init();

		_state.contracts.gov_token = gov_token;
		_state.contracts.sgov_token = sgov_token;

		// number of tokens to emit per block distributed among stakers depending on their share of the total staked
		// defaults to ~1 token per day distributed among stakers
		_state.emission.em_rate =  uint256(1e18) / 7200;
		_state.emission.last_emissions_block = block.number;

		_state.protocol_fee_percentage = 1000000000; // 10% (8 decimals)
		_state.treasury = msg.sender;

		// there are 7200 blocks in 24 hours (12 secs per block)
		// 720000 will give us 0.01 vp per day per staked token
		_state.vp_rate = 720000;
	}

	function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

	modifier onlySGovToken() {
		require(_msgSender() == _state.contracts.sgov_token, "caller is not staked governance token contract");
		_;
	}

	function update_accumulated_emissions() internal {
		if (block.number > _state.emission.last_emissions_block) {
			if (_state.total_staked > 0) {
				uint256 blocks_elapsed = block.number - _state.emission.last_emissions_block;
				uint256 emissions = blocks_elapsed * _state.emission.em_rate;
				_state.emission.acc_emissions_per_share += (emissions * 1e18) / _state.total_staked;
			} else {
				// if there are no stakers, reset the accumulated emissions per share
				_state.emission.acc_emissions_per_share = 0;
			}
			_state.emission.last_emissions_block = block.number;
		}
	}

	// vp is calculated to 3 decimal places
	function calculate_vp(address user) internal view returns (uint256) {
		uint256 blocks_elapsed;
		if (_state.user_data[user].is_staking) {
			blocks_elapsed = (block.number - _state.user_data[user].last_vp_block) * 1e18;
		} else {
			blocks_elapsed = 0;
		}
		uint256 vp = ((_state.user_data[user].staked_balance * blocks_elapsed) * 1000) / _state.vp_rate / 1e18;

		return vp;
	}

	function _stake(address user, uint256 amount) internal {
		require(amount > 0, "amount must be greater than 0");

		require((i_gov_token(_state.contracts.gov_token).balanceOf(address(this)) - _state.total_staked) > 0, "not enough tokens in protocol for emissions");

		update_accumulated_emissions();

		_state.user_data[user].emissions_debt += (amount * _state.emission.acc_emissions_per_share) / 1e18;

		if (_state.user_data[user].staked_balance == 0) {
            _state.stakers.push(user);
            _state.staker_index[user] = _state.stakers.length;
        }

		if (_state.user_data[user].is_staking) {
			uint256 realised_vp = calculate_vp(user);
			_state.user_data[user].voting_power += realised_vp;
			_state.total_vp += realised_vp;
		}
		_state.user_data[user].last_vp_block = block.number;

		_state.user_data[user].is_staking = true;
		_state.user_data[user].staked_balance += amount;
		_state.total_staked += amount;
	}

	function stake(uint256 amount) external nonReentrant {
		_stake(_msgSender(), amount);

		SafeERC20.safeTransferFrom(i_gov_token(_state.contracts.gov_token), _msgSender(), address(this), amount);
		i_sgov_token(_state.contracts.sgov_token).mint(_msgSender(), amount);

		emit Stake(_msgSender(), amount);
	}

	function _unstake(address user, uint256 amount) internal {
		require(_state.user_data[user].is_staking && (amount <= _state.user_data[user].staked_balance), "invalid unstake amount");

		update_accumulated_emissions();

		uint256 acc_emissions = (_state.user_data[user].staked_balance * _state.emission.acc_emissions_per_share) / 1e18;
    	_state.user_data[user].unclaimed_emissions += acc_emissions - _state.user_data[user].emissions_debt;
		_state.user_data[user].emissions_debt = acc_emissions - ((amount * _state.emission.acc_emissions_per_share) / 1e18);

		uint256 realised_vp = calculate_vp(user);
		_state.user_data[user].voting_power += realised_vp;
		_state.total_vp += realised_vp;
		_state.user_data[user].last_vp_block = block.number;

		_state.user_data[user].staked_balance -= amount;
		_state.total_staked -= amount;

		if (_state.user_data[user].staked_balance == 0) {
			_state.user_data[user].is_staking = false;
		}
	}

	function unstake(uint256 amount) external nonReentrant {
		_unstake(_msgSender(), amount);

		i_sgov_token(_state.contracts.sgov_token).burnFrom(_msgSender(), amount);
		SafeERC20.safeTransfer(i_gov_token(_state.contracts.gov_token), _msgSender(), amount);

		emit Unstake(_msgSender(), amount);
	}

	function claim() external nonReentrant {
		update_accumulated_emissions();

		uint256 acc_emissions = (_state.user_data[_msgSender()].staked_balance * _state.emission.acc_emissions_per_share) / 1e18;
		uint256 pending_emissions = acc_emissions + _state.user_data[_msgSender()].unclaimed_emissions - _state.user_data[_msgSender()].emissions_debt;

		require((i_gov_token(_state.contracts.gov_token).balanceOf(address(this)) - _state.total_staked) >= pending_emissions, "insufficent emissions for distribution");

		_state.user_data[_msgSender()].unclaimed_emissions = 0;
		_state.user_data[_msgSender()].emissions_debt = acc_emissions;

		if (pending_emissions > 0) {
			// calculate protocol reward
			uint256 protocol_reward = (pending_emissions * _state.protocol_fee_percentage) / 10000000000;
			uint256 user_reward = pending_emissions - protocol_reward;
			SafeERC20.safeTransfer(i_gov_token(_state.contracts.gov_token), _msgSender(), user_reward);
			SafeERC20.safeTransfer(i_gov_token(_state.contracts.gov_token), _state.treasury, protocol_reward);
		}

		emit Claim_Rewards(_msgSender(), pending_emissions);
	}

	function get_user_vp(address user) public view returns (uint256) {
		return _state.user_data[user].voting_power + calculate_vp(user);
	}

	function get_total_vp() external view returns (uint256) {
		uint256 total_vp;
        address[] memory users = get_all_stakers();
        for (uint256 i = 0; i < users.length; i++) {
            total_vp += get_user_vp(users[i]);
        }

        return total_vp;
	}

	function transfer_stake(address from, address to, uint256 amount) external nonReentrant onlySGovToken {
		_unstake(from, amount);
		_stake(to, amount);

		emit Transfer_Stake(from, to, amount);
	}
}
