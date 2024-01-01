// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title IDepositarium
 * @author DeployLabs.io
 *
 * @notice An interface for the GamerFi Depositarium contract.
 */
interface IDepositarium {
	/**
	 * @notice Withdrawal request structure that contains the details of a withdrawal request.
	 * @param player The address of the player.
	 * @param amount The amount of the withdrawal request. Specified in the smallest unit of the token.
	 * @param withdrawnTotal The total amount withdrawn. Used to prevent replay attacks.
	 * @param requestValidTill The timestamp until which the request is valid.
	 */
	struct WithdrawalRequest {
		address payable player;
		uint256 amount;
		uint256 withdrawnTotal;
		uint32 requestValidTill;
	}

	/**
	 * @notice Fee withdrawal request structure that contains the details of a fee withdrawal request.
	 * @param withdrawTo The address to withdraw the fees to.
	 * @param amount The amount of the withdrawal request. Specified in the smallest unit of the token.
	 */
	struct FeeWithdrawalRequest {
		address payable withdrawTo;
		uint256 amount;
	}

	/**
	 * @notice Emitted when a deposit is made by a player.
	 * @param player The address of the player.
	 * @param amount The deposit amount.
	 */
	event Deposited(address indexed player, uint256 amount);

	/**
	 * @notice Emitted when a deposit is made by a player for an instant-game.
	 * @param gameId ID of the game, the deposit is for.
	 * @param requestId ID of the request on the backend.
	 * @param player The address of the player.
	 * @param amount The deposit amount.
	 * @param prediction The prediction for the game outcome.
	 */
	event DepositedForInstantGame(
		uint8 indexed gameId,
		uint256 indexed requestId,
		address indexed player,
		uint256 amount,
		uint16 prediction
	);

	/**
	 * @notice Emitted when a withdrawal is made by a player.
	 * @param player The address of the player. Zero address is used for fees withdrawal.
	 * @param amount The withdrawal amount.
	 */
	event Withdrawn(address indexed player, uint256 amount);

	/**
	 * @notice Emitted when a contribution is made to the prize pool by the owner.
	 * @param amount The contribution amount.
	 */
	event ContributedToPrizePool(uint256 amount);

	/**
	 * @notice Emitted when a contribution is withdrawn from the prize pool.
	 * @param amount The withdrawal amount.
	 */
	event WithdrawnContributionFromPrizePool(uint256 amount);

	/**
	 * @notice Emitted when a payout is made to a player after an instant-game is finished.
	 * @param gameId ID of the game, the payout is for.
	 * @param requestId ID of the request on the backend.
	 * @param player The address of the player.
	 * @param amount The payout amount.
	 */
	event PaidOut(
		uint8 indexed gameId,
		uint256 indexed requestId,
		address indexed player,
		uint256 amount
	);

	/**
	 * @notice Error emitted when a zero is passed as an amount for a financial operation.
	 */
	error Depositarium__ZeroAmountNotAllowed();

	/**
	 * @notice Error emitted when a zero address is passed as a parameter.
	 */
	error Depositarium__ZeroAddressNotAllowed();

	/**
	 * @notice Error emitted when the caller is not eligible to call a function, accoridng to a signature.
	 */
	error Depositarium__NotAuthorized(address requestFor, address requestBy);

	/**
	 * @notice Error emitted when there is not enough funds to fulfill a request.
	 */
	error Depositarium__NotEnoughFunds(uint256 balance, uint256 requestedAmount);

	/**
	 * @notice Error emitted when a payout has already been paid out.
	 */
	error Depositarium__AlreadyPaidOut(uint8 gameId, uint256 requestId);

	/**
	 * @notice Error emitted when the amount of a contribution is less than the amount of a contribution withdrawal request.
	 */
	error Depositarium__ContributionLessThanWithdrawal(
		uint256 contribution,
		uint256 requestedAmount
	);

	/**
	 * @notice Error emitted when the signer of a withdrawal request is not the trusted signer.
	 */
	error Depositarium__UntrustedSigner(address trustedSigner, address requestSigner);

	/**
	 * @notice Error emitted when a signature is not longer valid, based on the total amount withdrawn value.
	 */
	error Depositarium__SignatureNotLongerValid();

	/**
	 * @notice Contribute to the prize pool.
	 */
	function contributeToPrizePool() external payable;

	/**
	 * @notice Deposit funds to the contract.
	 */
	function deposit() external payable;

	/**
	 * @notice Deposit funds to the contract for an instant-game.
	 *
	 * @param gameId ID of the game, the deposit is for.
	 * @param prediction The prediction for the game outcome.
	 */
	function depositForInstantGame(uint8 gameId, uint16 prediction) external payable;

	/**
	 * @notice Withdraw funds from the contract.
	 *
	 * @param withdrawalRequest The withdrawal request details.
	 * @param signature The signature of the withdrawal request.
	 */
	function withdraw(
		WithdrawalRequest calldata withdrawalRequest,
		bytes calldata signature
	) external;

	/**
	 * @notice Withdraw commission fees to a number of addresses.
	 *
	 * @param withdrawalRequests The withdrawal requests details.
	 */
	function withdrawFees(FeeWithdrawalRequest[] calldata withdrawalRequests) external;

	/**
	 * @notice Withdraw contributions from the prize pool.
	 *
	 * @param amount The amount to withdraw.
	 * @param withdrawTo The address to withdraw the funds to.
	 */
	function withdrawContributionFromPrizePool(uint256 amount, address payable withdrawTo) external;

	/**
	 * @notice Pay out to a player after an instant-game is finished.
	 *
	 * @param gameId ID of the game, the payout is for.
	 * @param requestId ID of the request on the backend.
	 * @param player The address of the player.
	 * @param amount The amount to pay out.
	 */
	function payOut(
		uint8 gameId,
		uint256 requestId,
		address payable player,
		uint256 amount
	) external;

	/**
	 * @notice Set the trusted signer for signing withdrawal requests.
	 *
	 * @param trustedSigner The address of the trusted signer.
	 */
	function setTrustedSigner(address trustedSigner) external;

	/**
	 * @notice Get the trusted signer for signing withdrawal requests.
	 *
	 * @return The address of the trusted signer.
	 */
	function getTrustedSigner() external view returns (address);

	/**
	 * @notice Get the amount of contributions made to the prize pool by the owner.
	 * @dev The contributions are deducted, when a contribution withdrawal is made.
	 *
	 * @return The amount of contributions made to the prize pool by the owner.
	 */
	function getPrizePoolContributionBalance() external view returns (uint256);

	/**
	 * @notice Check if a payout has already been paid out.
	 *
	 * @param gameId ID of the game, the payout is for.
	 * @param requestId ID of the request on the backend.
	 *
	 * @return True if the payout has already been paid out.
	 */
	function isAlreadyPaidOut(uint8 gameId, uint256 requestId) external view returns (bool);
}
