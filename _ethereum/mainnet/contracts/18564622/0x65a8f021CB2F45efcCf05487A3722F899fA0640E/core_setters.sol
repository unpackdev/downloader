// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

import "./OwnableUpgradeable.sol";

import "./core_state.sol";

contract Core_Setters is OwnableUpgradeable, Core_State {
	function set_operator(address _operator) external onlyOwner non_zero_address(_operator) {
		_state.operator = _operator;
	}

	function set_validator_capacity(uint256 _validator_capacity) external onlyOwner {
		require(_validator_capacity > 0, "validator capacity must be greater than 0");

		_state.constants.validator_capacity = _validator_capacity;
	}

	modifier non_zero_address(address _address) {
		require(_address != address(0), "address cannot be 0");
		_;
	}

	function set_ls_token_contract(address _ls_token) external onlyOwner non_zero_address(_ls_token) {
		_state.contracts.ls_token = _ls_token;
	}

	function set_withdraw_contract(address _withdraw) external onlyOwner non_zero_address(_withdraw) {
		_state.contracts.withdraw = _withdraw;
	}

	function set_abyss_eth2_depositor_contract(address _abyss_eth2_depositor) external onlyOwner non_zero_address(_abyss_eth2_depositor) {
		_state.contracts.abyss_eth2_depositor = _abyss_eth2_depositor;
	}

	function set_treasury_address(address _treasury) external onlyOwner non_zero_address(_treasury) {
		_state.treasury = _treasury;
	}

	function set_protocol_fee_percentage(uint256 _protocol_fee_percentage) external onlyOwner {
		require(_protocol_fee_percentage <= 10000000000, "protocol fee percentage only supports 8 decimals");

		_state.protocol_fee_percentage = _protocol_fee_percentage;
	}

	function set_protocol_float(uint256 _protocol_float) external onlyOwner {
		_state.protocol_float = _protocol_float;
	}

	// should only be used if we somehow unstaked from validators without user withdrawals
	function add_unstaked_validators(uint256 _unstaked_validators) external onlyOwner {
		_state.withdrawals.unstaked_validators += _unstaked_validators;
	}
	function sub_unstaked_validators(uint256 _unstaked_validators) external onlyOwner {
		_state.withdrawals.unstaked_validators -= _unstaked_validators;
	}

	// should only be used if we are somehow redeploying the contract and reusing the previous validator mnemonic
	function set_validator_index(uint256 _validator_index) external onlyOwner {
		_state.validator_index = _validator_index;
	}
}
