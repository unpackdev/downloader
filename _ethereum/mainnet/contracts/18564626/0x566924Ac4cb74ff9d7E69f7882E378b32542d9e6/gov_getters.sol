// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

import "./gov_state.sol";
import "./i_gov_token.sol";

contract Gov_Getters is Gov_State {
	function get_gov_token() external view returns (address) {
		return _state.contracts.gov_token;
	}

	function get_sgov_token() external view returns (address) {
		return _state.contracts.sgov_token;
	}

	function get_treasury_address() external view returns (address) {
		return _state.treasury;
	}

	function get_protocol_fee_percentage() external view returns (uint256) {
		return _state.protocol_fee_percentage;
	}

	function get_emission_rate() external view returns (uint256) {
		return _state.emission.em_rate;
	}

	function get_vp_rate() external view returns (uint256) {
		return _state.vp_rate;
	}

	function get_all_stakers() public view returns (address[] memory) {
        return _state.stakers;
    }

	function get_user_data(address user) external view returns (Gov_Storage.User_Data memory) {
		return _state.user_data[user];
	}

	function get_total_staked() external view returns (uint256) {
		return _state.total_staked;
	}

	function get_pending_emissions(address user) external view returns (uint256) {
		uint256 acc_emissions_per_share = _state.emission.acc_emissions_per_share;
		if (block.number > _state.emission.last_emissions_block) {
			uint256 blocks_elapsed = block.number - _state.emission.last_emissions_block;
			uint256 emissions = blocks_elapsed * _state.emission.em_rate;
			if (_state.total_staked > 0) {
				acc_emissions_per_share += (emissions * 1e18) / _state.total_staked;
			}
		}
		uint256 pending = ((_state.user_data[user].staked_balance * acc_emissions_per_share) / 1e18) + _state.user_data[user].unclaimed_emissions - _state.user_data[user].emissions_debt;

		return pending;
	}

	function get_unpending_vp() external view returns (uint256) {
		return _state.total_vp;
	}
}
