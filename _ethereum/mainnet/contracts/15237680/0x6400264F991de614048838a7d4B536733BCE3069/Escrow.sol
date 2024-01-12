// SPDX-License-Identifier: MPL-2.0
pragma solidity 0.8.7;

import "./IERC20.sol";

/// @title Gateway Fee Escrow
/// @notice Handles Ether and ERC20
contract Escrow {
	/// @notice maps user to token and credited amount
	mapping(address => mapping(address => uint256)) internal _gatewayFees;

	event Deposited(
		address indexed payee,
		address indexed token,
		uint256 amount
	);
	event Withdrawn(
		address indexed payee,
		address indexed token,
		uint256 amount
	);

	constructor() {}

	/// @notice Deposit fee
	/// @param gatewayAddress where the fee credited
	/// @param amount credited
	/// @param token should be address(0) for Ether, otherwise ERC20 token address
	function _deposit(
		address gatewayAddress,
		uint256 amount,
		address token
	) internal {
		_gatewayFees[gatewayAddress][token] += amount;
		emit Deposited(gatewayAddress, token, amount);
	}

	/// @notice Claim
	/// @param token should be address(0) for Ether, otherwise ERC20 token address
	function claim(address token) external {
		uint256 payment = _gatewayFees[msg.sender][token];
		_gatewayFees[msg.sender][token] = 0;

		if (token == address(0)) {
			// Transfer Ether
			payable(msg.sender).transfer(payment);
		} else {
			// Transfer ERC20
			IERC20(token).transfer(msg.sender, payment);
		}

		emit Withdrawn(msg.sender, token, payment);
	}

	/// @notice Gateway Fee of address
	/// @param user credited
	/// @param token should be address(0) for Ether, otherwise ERC20 token address
	/// @return uint256 of amount credited to address
	function gatewayFees(address user, address token)
		external
		view
		returns (uint256)
	{
		return _gatewayFees[user][token];
	}
}
