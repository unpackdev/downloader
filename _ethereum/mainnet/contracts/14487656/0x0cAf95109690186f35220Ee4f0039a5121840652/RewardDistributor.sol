// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "./Pausable.sol";
import "./SpoolOwnable.sol";
import "./IRewardDistributor.sol";

import "./SafeERC20.sol";

/**
 * @notice Implementation of the {IRewardDistributor} interface.
 *
 * @dev
 * This contract has the simple logic to distribute ERC20 tokens
 * to the desired address (e.g. SpoolStaking).
 * It can be called from the whitelisted addresses to pay the rewards.
 *
 * Reward tokens should be sent to this contract in advance.
 *
 * The contract is pausable by the Spool DAO or the pauser.
 */
contract RewardDistributor is Pausable, SpoolOwnable, IRewardDistributor {
	using SafeERC20 for IERC20;

	/* ========== STATE VARIABLES ========== */

	/// @notice Is the address reward distributor
	/// @dev e.g. Spool staking contract
	mapping(address => bool) public isDistributor;

	/// @notice Can the address pause the contract
	mapping(address => bool) public isPauser;

	/* ========== CONSTRUCTOR ========== */

	/**
	 * @notice Sets the Spool DAO owner contract
	 *
	 * @param _spoolOwner Spool DAO owner contract
	 */
	constructor(ISpoolOwner _spoolOwner) SpoolOwnable(_spoolOwner) {}

	/* ========== DISTRIBUTE REWARDS FUNCTIONS ========== */

	/**
	 * @notice Pay ERC20 token rewards to `account`
	 * @dev
	 * Requirements:
	 *
	 * - the caller must be the distributor
	 *
	 * @param account address to retrieve the token to
	 * @param tokens ERC20 tokens to send
	 * @param amounts amount of rewards to send
	 */
	function payRewards(
		address account,
		IERC20[] memory tokens,
		uint256[] memory amounts
	) external override whenNotPaused onlyDistributor {
		require(
			tokens.length == amounts.length,
			"RewardDistributor::payRewards: Tokens should be of same length as amounts"
		);

		for (uint256 i = 0; i < tokens.length; i++) {
			_payReward(account, tokens[i], amounts[i]);
		}
	}

	/**
	 * @notice Pay ERC20 token reward to `account`
	 * @dev
	 * Requirements:
	 *
	 * - the caller must be the distributor
	 *
	 * @param account address to retrieve the token to
	 * @param token ERC20 token to send
	 * @param amount amount of reward to send
	 */
	function payReward(
		address account,
		IERC20 token,
		uint256 amount
	) external override whenNotPaused onlyDistributor {
		_payReward(account, token, amount);
	}

	/**
	 * @notice Pay ERC20 token reward to `account`
	 *
	 * @param account address to retrieve the token to
	 * @param token ERC20 token to send
	 * @param amount amount of reward to send
	 */
	function _payReward(
		address account,
		IERC20 token,
		uint256 amount
	) private {
		token.safeTransfer(account, amount);
		emit RewardPaid(token, account, amount);
	}

	/* ========== OWNER FUNCTIONS ========== */

	/**
	 * @notice Retrieve the reward tokens from this contract
	 *
	 * @dev
	 * Requirements:
	 *
	 * - the caller must be the contract owner (Spool DAO)
	 *
	 * @param account address to retrieve the token to
	 * @param token ERC20 token to retrieve
	 * @param amount amount to retrieve
	 */
	function retrieveRewards(
		address account,
		IERC20 token,
		uint256 amount
	) external onlyOwner {
		token.safeTransfer(account, amount);
		emit RewardRetrieved(token, account, amount);
	}

	/**
	 * @notice Add or remove the reward distributer
	 *
	 * @dev
	 * Requirements:
	 *
	 * - the caller must be the contract owner (Spool DAO)
	 *
	 * @param account address to manage the distributer role for
	 * @param _set true to set the role, flase to remove
	 */
	function setDistributor(address account, bool _set) external onlyOwner {
		isDistributor[account] = _set;
		emit DistributorUpdated(account, _set);
	}

	/**
	 * @notice Add or remove the pauser role
	 *
	 * @dev
	 * Requirements:
	 *
	 * - the caller must be the contract owner (Spool DAO)
	 *
	 * @param account address to manage the pauser role for
	 * @param _set true to set the role, flase to remove
	 */
	function setPauser(address account, bool _set) external onlyOwner {
		isPauser[account] = _set;
		emit PauserUpdated(account, _set);
	}

	/**
	 * @notice Resumes the reward distribution.
	 *
	 * @dev
	 * Requirements:
	 *
	 * - the caller must be the contract owner (Spool DAO)
	 */
	function unpause() external onlyOwner {
		_unpause();
	}

	/* ========== PAUSE FUNCTION ========== */

	/**
	 * @notice Stops the controller.
	 * @dev
	 * Requirements:
	 *
	 * - the caller must be the pauser or the contract owner (Spool DAO)
	 */
	function pause() external onlyPauser {
		_pause();
	}

	/* ========== RESTRICTION FUNCTIONS ========== */

	/**
	 * @notice Ensures the caller is the reward distributor
	 */
	function _onlyDistributor() private view {
		require(isDistributor[msg.sender], "RewardDistributor::_onlyDistributor: Not a distributor");
	}

	/**
	 * @notice Ensures that the caller is the pauser
	 */
	function _onlyPauser() private view {
		require(isPauser[msg.sender] || isSpoolOwner(), "Controller::_onlyPauser: Can only be invoked by pauser");
	}

	/* ========== MODIFIERS ========== */

	/**
	 * @notice Throws if the caller is not the distributor
	 */
	modifier onlyDistributor() {
		_onlyDistributor();
		_;
	}

	/**
	 * @notice Throws if the calling user is not pauser
	 */
	modifier onlyPauser() {
		_onlyPauser();
		_;
	}
}
