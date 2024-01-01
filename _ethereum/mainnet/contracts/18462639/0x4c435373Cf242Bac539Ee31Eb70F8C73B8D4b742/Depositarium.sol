// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./IDepositarium.sol";

import "./AccessControl.sol";
import "./EIP712.sol";

/**
 * @title GamerFi Depositarium v2.2
 * @author DeployLabs.io
 *
 * @notice A contract for managing deposits and withdrawals to and from the GamerFi platform.
 */
contract Depositarium is IDepositarium, EIP712("GamerFi Depositarium", "2.2"), AccessControl {
	bytes32 public constant ACCOUNTANT_ROLE = keccak256("ACCOUNTANT_ROLE");

	address private s_trustedSigner;
	uint256 private s_prizePoolContributionBalance;

	// Total amount of money withdrawn. Zero address is used for fees.
	mapping(address => uint256) private s_totalWithdrawn;
	uint256 private s_latestRequestId;

	// Mapping of gameId to requestId to wether or not this game has been paid out for
	mapping(uint8 => mapping(uint256 => bool)) private s_paidOut;

	constructor() {
		_grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
	}

	function contributeToPrizePool() external payable onlyRole(DEFAULT_ADMIN_ROLE) {
		if (msg.value == 0) revert Depositarium__ZeroAmountNotAllowed();

		emit ContributedToPrizePool(msg.value);
		s_prizePoolContributionBalance += msg.value;
	}

	function deposit() external payable {
		if (msg.value == 0) revert Depositarium__ZeroAmountNotAllowed();

		emit Deposited(msg.sender, msg.value);
	}

	function depositForInstantGame(uint8 gameId, uint16 prediction) external payable {
		if (msg.value == 0) revert Depositarium__ZeroAmountNotAllowed();

		uint256 requestId = ++s_latestRequestId;
		emit DepositedForInstantGame(gameId, requestId, msg.sender, msg.value, prediction);
	}

	function withdraw(
		WithdrawalRequest calldata withdrawalRequest,
		bytes calldata signature
	) external {
		_withdraw(withdrawalRequest, signature, msg.sender, payable(msg.sender));
	}

	function withdrawFees(
		FeeWithdrawalRequest[] calldata withdrawalRequests
	) external onlyRole(DEFAULT_ADMIN_ROLE) {
		for (uint32 i = 0; i < withdrawalRequests.length; i++) {
			FeeWithdrawalRequest memory withdrawalRequest = withdrawalRequests[i];

			if (withdrawalRequest.amount > address(this).balance)
				revert Depositarium__NotEnoughFunds(
					address(this).balance,
					withdrawalRequest.amount
				);

			emit Withdrawn(withdrawalRequest.withdrawTo, withdrawalRequest.amount);

			withdrawalRequest.withdrawTo.transfer(withdrawalRequest.amount);
		}
	}

	function withdrawContributionFromPrizePool(
		uint256 amount,
		address payable withdrawTo
	) external onlyRole(DEFAULT_ADMIN_ROLE) {
		if (amount > s_prizePoolContributionBalance)
			revert Depositarium__ContributionLessThanWithdrawal(
				s_prizePoolContributionBalance,
				amount
			);
		if (amount > address(this).balance)
			revert Depositarium__NotEnoughFunds(address(this).balance, amount);

		s_prizePoolContributionBalance -= amount;
		emit WithdrawnContributionFromPrizePool(amount);

		withdrawTo.transfer(amount);
	}

	function payOut(
		uint8 gameId,
		uint256 requestId,
		address payable player,
		uint256 amount
	) external onlyRole(ACCOUNTANT_ROLE) {
		if (amount > address(this).balance)
			revert Depositarium__NotEnoughFunds(address(this).balance, amount);
		if (s_paidOut[gameId][requestId]) revert Depositarium__AlreadyPaidOut(gameId, requestId);

		s_paidOut[gameId][requestId] = true;

		emit PaidOut(gameId, requestId, player, amount);

		player.transfer(amount);
	}

	function setTrustedSigner(address trustedSigner) external onlyRole(DEFAULT_ADMIN_ROLE) {
		if (trustedSigner == address(0)) revert Depositarium__ZeroAddressNotAllowed();

		s_trustedSigner = trustedSigner;
	}

	function getTrustedSigner() external view returns (address) {
		return s_trustedSigner;
	}

	function getPrizePoolContributionBalance() external view returns (uint256) {
		return s_prizePoolContributionBalance;
	}

	function isAlreadyPaidOut(uint8 gameId, uint256 requestId) external view returns (bool) {
		return s_paidOut[gameId][requestId];
	}

	function _withdraw(
		WithdrawalRequest calldata withdrawalRequest,
		bytes calldata signature,
		address withdrawalTracker,
		address payable withdrawTo
	) internal {
		address requestSigner = _getWithdrawalRequestSigner(withdrawalRequest, signature);
		if (requestSigner != s_trustedSigner)
			revert Depositarium__UntrustedSigner(s_trustedSigner, requestSigner);

		if (withdrawalRequest.player != msg.sender)
			revert Depositarium__NotAuthorized(withdrawalRequest.player, msg.sender);
		if (withdrawalRequest.amount > address(this).balance)
			revert Depositarium__NotEnoughFunds(address(this).balance, withdrawalRequest.amount);
		if (withdrawalRequest.withdrawnTotal != s_totalWithdrawn[withdrawalTracker])
			revert Depositarium__SignatureNotLongerValid();
		if (withdrawalRequest.requestValidTill < block.timestamp)
			revert Depositarium__SignatureNotLongerValid();

		s_totalWithdrawn[withdrawalTracker] += withdrawalRequest.amount;
		emit Withdrawn(withdrawalTracker, withdrawalRequest.amount);

		withdrawTo.transfer(withdrawalRequest.amount);
	}

	function _getWithdrawalRequestSigner(
		WithdrawalRequest calldata withdrawalRequest,
		bytes calldata signature
	) internal view returns (address) {
		bytes32 digest = _hashTypedDataV4(
			keccak256(
				abi.encode(
					keccak256(
						"WithdrawalRequest(address player,uint256 amount,uint256 withdrawnTotal,uint32 requestValidTill)"
					),
					withdrawalRequest.player,
					withdrawalRequest.amount,
					withdrawalRequest.withdrawnTotal,
					withdrawalRequest.requestValidTill
				)
			)
		);

		return ECDSA.recover(digest, signature);
	}
}
