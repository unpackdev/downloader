//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/**
 * @notice IVault is the interface to implement custody.
 */
interface IVault {
	// ======================
	// Structs
	// ======================
	struct Allocation {
		address asset;
		uint256 amount;
	}

	struct Payload {
		bytes32 action;
		bytes32 rid;
		uint64 expire;
		address destination;
		Allocation[] allocations;
		address implAddress;
		uint256 chainId;
	}

	// ======================
	// Functions
	// ======================

	/**
	 * @notice The setup function sets addresses of the broker and coSigner.
	 * @dev Require DEFAULT_ADMIN_ROLE to invoke. NOTE: once addresses are set, there is no way to change them if their private key is lost. In such case, vault implementation contract becomes useless and requires an upgrade.
	 * @param brokerAddress Address derived from broker public key.
	 * @param coSignerAddress Address derived from coSigner public key.
	 */
	function setup(address brokerAddress, address coSignerAddress) external;

	/**
	 * @notice Get last ledger id (deposits and withdrawals id).
	 * @return uint256 Ledger id.
	 */
	function getLastId() external view returns (uint256);

	/**
	 * @notice Get broker (only public key it is derived from exists) key for this vault.
	 * @dev Get broker (only public key it is derived from exists) key for this vault.
	 * @return address Broker address for this vault.
	 */
	function getBrokerAddress() external view returns (address);

	/**
	 * @notice Set the address derived from the broker's new public key. Emits `BrokerAddressSet` event.
	 * @dev Supplied payload must be signed by broker's current public key.
	 * @param address_ New broker address.
	 * @param signature New address signed by broker's current public key.
	 */
	function setBrokerAddress(address address_, bytes calldata signature) external;

	/**
	 * @notice Get coSigner (only public key it is derived from exists) key for this vault.
	 * @dev Get coSigner (only public key it is derived from exists) key for this vault.
	 * @return address CoSigner address for this vault.
	 */
	function getCoSignerAddress() external view returns (address);

	/**
	 * @notice Set the address derived from the coSigner's new public key. Emits `CoSignerAddressSet` event.
	 * @dev Supplied payload must be signed by coSigner's current public key.
	 * @param address_ New coSigner address.
	 * @param signature New address signed by coSigner's current public key.
	 */
	function setCoSignerAddress(address address_, bytes calldata signature) external;

	/**
	 * @notice Deposit assets with given payload from the caller. Emits `Deposited` event.
	 * @param payload Deposit payload.
	 * @param brokerSignature Payload signed by the Broker.
	 * @param otpSignature Payload signed by the CoSigner service.
	 */
	function deposit(
		Payload calldata payload,
		bytes calldata brokerSignature,
		bytes calldata otpSignature
	) external payable;

	/**
	 * @notice Withdraw assets with given payload to the destination specified in the payload. Emits `Withdrawn` event.
	 * @param payload Withdraw payload.
	 * @param brokerSignature Payload signed by the Broker.
	 * @param otpSignature Payload signed by the CoSigner service.
	 */
	function withdraw(
		Payload calldata payload,
		bytes calldata brokerSignature,
		bytes calldata otpSignature
	) external payable;

	/**
	 * @notice Address derived from broker's new public key is set.
	 * @param newBrokerAddress Updated Broker address.
	 */
	event BrokerAddressSet(address indexed newBrokerAddress);

	/**
	 * @notice Address derived from CoSigner's new public key is set.
	 * @param newCoSignerAddress Updated CoSigner address.
	 */
	event CoSignerAddressSet(address indexed newCoSignerAddress);

	// ======================
	// Events
	// ======================
	/**
	 * @notice Deposited event.
	 * @param id Ledger id.
	 * @param account Account address.
	 * @param asset Asset address deposited.
	 * @param amount Quantity of assets deposited.
	 * @param rid Request id from broker.
	 */
	event Deposited(
		uint256 indexed id,
		address indexed account,
		address indexed asset,
		uint256 amount,
		bytes32 rid
	);

	/**
	 * @notice Withdrawn event.
	 * @param id Ledger id.
	 * @param destination Destination address.
	 * @param asset Asset address withdrawn.
	 * @param amount Quantity of assets withdrawn.
	 * @param rid Request id from broker.
	 */
	event Withdrawn(
		uint256 indexed id,
		address indexed destination,
		address indexed asset,
		uint256 amount,
		bytes32 rid
	);
}
