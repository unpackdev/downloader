//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./Counters.sol";
import "./ECDSA.sol";
import "./ERC20.sol";

import "./VaultImplBase.sol";
import "./IVault.sol";

// TODO: Benchmark if storing error messages as constants is cheaper than using string literals.

/**
 * @dev Implementation for the Proxy. Version 1.0.
 */
contract VaultImplV1 is VaultImplBase, IVault {
	using ECDSA for bytes32;
	using Counters for Counters.Counter;

	/**
	 * Deposit type identifier value.
	 */
	bytes32 public constant DEPOSIT_ACTION = keccak256('YELLOW_VAULT_DEPOSIT_ACTION');

	/**
	 * Withdrawal type identifier value.
	 */
	bytes32 public constant WITHDRAW_ACTION = keccak256('YELLOW_VAULT_WITHDRAW_ACTION');

	bool private _isSetup = false;

	// Not a real address, only public key exists.
	address private _brokerAddress;
	// Not a real address, only public key exists.
	address private _coSignerAddress;

	Counters.Counter private _ledgerId;

	// Keep track of used signatures to prevent reuse before expiration.
	mapping(address => mapping(bytes32 => bool)) private _sigUsage;

	/**
	 * @notice Revert if hash of supplied signature was already used by the issuer.
	 * @dev Revert if hash of supplied signature was already used by the issuer.
	 * @param issuer Account using supplied signature.
	 * @param signature Signature used as identifier for action requested from vault.
	 */
	function _requireSigNotUsed(address issuer, bytes memory signature) internal view {
		require(!_sigUsage[issuer][keccak256(signature)], 'Signature already used');
	}

	/**
	 * @notice Check supplied signature to be indeed signed by claimed signer.
	 * @dev Check supplied signature to be indeed signed by claimed signer.
	 * @param signer Signer claimed to have signed the payload.
	 * @param encodedData Encoded data, which denotes action to be performed.
	 * @param signature Payload signed by claimed signer.
	 */
	function _requireValidSignature(
		address signer,
		bytes memory encodedData,
		bytes memory signature
	) internal pure {
		require(
			keccak256(encodedData).toEthSignedMessageHash().recover(signature) == signer,
			'Invalid signature'
		);
	}

	function _requireValidAddress(address address_) internal pure {
		require(address_ != address(0), 'Invalid address');
	}

	/**
	 * @notice Check that payload data is correct: expire timestamp is due, destination is not zero address, there is no zero allocation amount, implementation address specified is this contract and chain id is indeed this chain's id.
	 * @dev Check that payload data is correct: expire timestamp is due, destination is not zero address, there is no zero allocation amount, implementation address specified is this contract and chain id is indeed this chain's id.
	 * @param payload Payload structure, which denotes action to be performed.
	 */
	function _checkPayload(Payload memory payload) internal view {
		require(payload.expire > block.timestamp, 'Request expired'); //solhint-disable-line not-rely-on-time
		require(payload.destination != address(0), 'Destination is zero address');

		for (uint256 i = 0; i < payload.allocations.length; i++) {
			require(payload.allocations[i].amount > 0, 'Amount is zero');
		}

		require(payload.implAddress == _getImplementation(), 'Invalid implementation address');
		require(payload.chainId == getChainId(), 'Invalid chain id');
	}

	/**
	 * @notice Mark the signature as used by the issuer.
	 * @dev Mark the signature as used by the issuer.
	 * @param issuer User issuer address.
	 * @param signature Signature used as identifier for action requested from vault.
	 */
	function _useSignature(address issuer, bytes memory signature) internal {
		_sigUsage[issuer][keccak256(signature)] = true;
	}

	/**
	 * @notice Return chain id.
	 * @dev Return chain id.
	 * @return uint256 Chain id.
	 */
	function getChainId() internal view returns (uint256) {
		uint256 id;
		/* solhint-disable no-inline-assembly */
		assembly {
			id := chainid()
		}

		/* solhint-disable no-inline-assembly */
		return id;
	}

	/**
	 * @notice The setup function sets addresses of the broker and coSigner.
	 * @dev Require DEFAULT_ADMIN_ROLE to invoke. NOTE: once addresses are set, there is no way to change them if their private key is lost. In such case, vault implementation contract becomes useless and requires an upgrade.
	 * @param brokerAddress Address derived from broker public key.
	 * @param coSignerAddress Address derived from coSigner public key.
	 */
	function setup(address brokerAddress, address coSignerAddress)
		external
		onlyProxy
		onlyRole(DEFAULT_ADMIN_ROLE)
	{
		require(!_isSetup, 'Vault is already setup');

		_requireValidAddress(brokerAddress);
		_requireValidAddress(coSignerAddress);

		_isSetup = true;

		_brokerAddress = brokerAddress;
		_coSignerAddress = coSignerAddress;
	}

	/**
	 * @notice Get last ledger id (deposits and withdrawals id).
	 * @dev Get last ledger id (deposits and withdrawals id).
	 * @return uint256 Ledger id.
	 */
	function getLastId() external view override onlyProxy returns (uint256) {
		return _ledgerId.current();
	}

	/**
	 * @notice Get broker (only public key it is derived from exists) key for this vault.
	 * @dev Get broker (only public key it is derived from exists) key for this vault.
	 * @return address Broker (only public key it is derived from exists) key.
	 */
	function getBrokerAddress() external view onlyProxy returns (address) {
		return _brokerAddress;
	}

	/**
	 * @notice Set the address derived from the broker's new public key. Emits `BrokerAddressSet` event.
	 * @dev Supplied payload must be signed by broker's current public key.
	 * @param address_ New broker address.
	 * @param signature New address signed by broker's current public key.
	 */
	function setBrokerAddress(address address_, bytes calldata signature) external onlyProxy {
		_requireValidSignature(_brokerAddress, abi.encode(address_), signature);
		_requireValidAddress(address_);

		_brokerAddress = address_;

		emit BrokerAddressSet(address_);
	}

	/**
	 * @notice Get coSigner (only public key it is derived from exists) key for this vault.
	 * @dev Get coSigner (only public key it is derived from exists) key for this vault.
	 * @return address CoSigner (only public key it is derived from exists) key.
	 */
	function getCoSignerAddress() external view onlyProxy returns (address) {
		return _coSignerAddress;
	}

	/**
	 * @notice Set the address derived from the coSigner's new public key. Emits `CoSignerAddressSet` event.
	 * @dev Supplied payload must be signed by coSigner's current public key.
	 * @param address_ New coSigner address.
	 * @param signature New address signed by coSigner's current public key.
	 */
	function setCoSignerAddress(address address_, bytes calldata signature) external onlyProxy {
		_requireValidSignature(_coSignerAddress, abi.encode(address_), signature);
		_requireValidAddress(address_);

		_coSignerAddress = address_;

		emit CoSignerAddressSet(address_);
	}

	/**
	 * @notice Deposit assets with given payload from the caller. Emits `Deposited` event.
	 * @dev Deposit assets with given payload from the caller. Emits `Deposited` event.
	 * @param payload Deposit payload.
	 * @param brokerSignature Payload signed by the broker.
	 * @param coSignerSignature Payload signed by the coSigner.
	 */
	function deposit(
		Payload calldata payload,
		bytes calldata brokerSignature,
		bytes calldata coSignerSignature
	) external payable onlyProxy {
		address issuer = msg.sender;

		// check signatures
		_requireSigNotUsed(issuer, brokerSignature);
		_requireSigNotUsed(issuer, coSignerSignature);

		bytes memory encodedPayload = abi.encode(payload);
		_requireValidSignature(_brokerAddress, encodedPayload, brokerSignature);
		_requireValidSignature(_coSignerAddress, encodedPayload, coSignerSignature);

		// check payload
		_checkPayload(payload);

		require(payload.action == DEPOSIT_ACTION, 'Invalid action');
		require(payload.destination == issuer, 'Invalid destination');

		// use signatures
		_useSignature(issuer, brokerSignature);
		_useSignature(issuer, coSignerSignature);

		// deposit allocations
		for (uint256 i = 0; i < payload.allocations.length; i++) {
			address asset = payload.allocations[i].asset;
			uint256 amount = payload.allocations[i].amount;

			if (asset == address(0)) {
				require(msg.value == amount, 'Incorrect msg.value');
			} else {
				bool success = IERC20(asset).transferFrom(
					payload.destination,
					address(this),
					amount
				);

				// require successful deposit before updating holdings (protect against reentrancy)
				require(success, 'Could not deposit ERC20');
			}

			_ledgerId.increment();

			emit Deposited(
				_ledgerId.current(),
				payload.destination,
				payload.allocations[i].asset,
				payload.allocations[i].amount,
				payload.rid
			);
		}
	}

	/**
	 * @notice Withdraw assets with given payload to the destination specified in the payload. Emits `Withdrawn` event.
	 * @dev Withdraw assets with given payload to the destination specified in the payload. Emits `Withdrawn` event.
	 * @param payload Withdraw payload.
	 * @param brokerSignature Payload signed by the Broker.
	 * @param coSignerSignature Payload signed by the coSigner.
	 */
	function withdraw(
		Payload calldata payload,
		bytes calldata brokerSignature,
		bytes calldata coSignerSignature
	) external payable onlyProxy {
		address issuer = msg.sender;

		// check signatures
		_requireSigNotUsed(issuer, brokerSignature);
		_requireSigNotUsed(issuer, coSignerSignature);

		bytes memory encodedPayload = abi.encode(payload);
		_requireValidSignature(_brokerAddress, encodedPayload, brokerSignature);
		_requireValidSignature(_coSignerAddress, encodedPayload, coSignerSignature);

		// check payload
		_checkPayload(payload);

		require(payload.action == WITHDRAW_ACTION, 'Invalid action');

		// use signatures
		_useSignature(issuer, brokerSignature);
		_useSignature(issuer, coSignerSignature);

		// withdraw allocations
		for (uint256 i = 0; i < payload.allocations.length; i++) {
			address asset = payload.allocations[i].asset;
			uint256 amount = payload.allocations[i].amount;

			if (asset == address(0)) {
				(bool success, ) = payload.destination.call{value: amount}(''); //solhint-disable-line avoid-low-level-calls

				require(success, 'Could not transfer ETH');
			} else {
				bool success = IERC20(asset).transfer(payload.destination, amount);

				require(success, 'Could not transfer ERC20');
			}

			_ledgerId.increment();

			emit Withdrawn(
				_ledgerId.current(),
				payload.destination,
				payload.allocations[i].asset,
				payload.allocations[i].amount,
				payload.rid
			);
		}
	}
}
