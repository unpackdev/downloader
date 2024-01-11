// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./VRFConsumerBaseV2Upgradable.sol";
import "./VRFCoordinatorV2Interface.sol";
import "./Initializable.sol";

error AccountHasPendingMint(address _account);
error AcountHasNoPendingMint(address _account);
error InvalidAccount();
error InvalidRequestBase();
error InvalidRequestCount();
error RevealNotReady();

abstract contract Generator is VRFConsumerBaseV2Upgradable {
	VRFCoordinatorV2Interface internal vrfCoordinator;
	bytes32 internal keyHash;
	uint64 internal subscriptionId;
	uint32 internal callbackGasLimit;

	struct Mint {
		uint64 base;
		uint32 count;
		uint256[] random;
	}
	mapping(uint256 => address) internal mintRequests;
	mapping(address => Mint) internal pendingMints;

	event Requested(address indexed _account, uint256 _baseId, uint256 _count);
	event Pending(address indexed _account, uint256 _baseId, uint256 _count);
	event Revealed(address indexed _account, uint256 _tokenId);

	/**
	 * Constructor to initialize VRF
	 * @param _vrfCoordinator VRF Coordinator address
	 * @param _keyHash Gas lane key hash
	 * @param _subscriptionId VRF subscription id
	 * @param _callbackGasLimit VRF callback gas limit
	 */
	function __Generator_init(
		address _vrfCoordinator,
		bytes32 _keyHash,
		uint64 _subscriptionId,
		uint32 _callbackGasLimit
	) internal onlyInitializing {
		__VRFConsumerBaseV2_init(_vrfCoordinator);
		vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
		keyHash = _keyHash;
		subscriptionId = _subscriptionId;
		callbackGasLimit = _callbackGasLimit;
	}
	
	// -- PUBLIC -- 

	modifier zeroPending(address _account) {
		if (pendingMints[_account].base != 0) revert AccountHasPendingMint(_account);
		_;
	}

	/**
	 * Get the current pending mints of a user account
	 * @param _account Address of account to query
	 * @return Pending token base ID, amount of pending tokens
	 */
	function pendingOf(address _account) public view returns (uint256, uint256) {
		return (pendingMints[_account].base, pendingMints[_account].random.length);
	}

	// -- INTERNAL --

	/**
	 * Update pending mint with response from VRF
	 * @param _requestId Request ID that was fulfilled
	 * @param _randomWords Received random numbers
	 */
	function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal virtual override {
		// Pop request
		address account = mintRequests[_requestId];
		delete mintRequests[_requestId];

		// Update pending mints with received random numbers
		pendingMints[account].random = _randomWords;

		// Ready to reveal
		emit Pending(account, pendingMints[account].base, _randomWords.length);
	}

	/**
	 * Setup a pending mint and request numbers from VRF
	 * @param _account Account to request for
	 * @param _base Base token ID
	 * @param _count Number of tokens
	 */
	function _request(address _account, uint256 _base, uint256 _count) internal zeroPending(_account) {
		if (_account == address(0)) revert InvalidAccount();
		if (_base == 0) revert InvalidRequestBase();
		if (_count == 0) revert InvalidRequestCount();
		// Request random numbers for tokens, save request id to account
		uint256 requestId = vrfCoordinator.requestRandomWords(
			keyHash,
			subscriptionId,
			3,
			callbackGasLimit,
			uint32(_count)
		);
		mintRequests[requestId] = _account;
		// Initialize mint request with id and count
		pendingMints[_account].base = uint64(_base);
		pendingMints[_account].count = uint32(_count);
		// Mint requested
		emit Requested(_account, _base, _count);
	}

	/**
	 * Reveal pending tokens with received random numbers
	 * @param _account Account to reveal for
	 */
	function _reveal(address _account) internal {
		if (_account == address(0)) revert InvalidAccount();
		Mint memory mint = pendingMints[_account];
		if (mint.base == 0) revert AcountHasNoPendingMint(_account);
		if (mint.random.length == 0) revert RevealNotReady();
		delete pendingMints[_account];
		// Generate all tokens
		for (uint256 i; i < mint.count; i++) {
			_revealToken(mint.base + i, mint.random[i]);
			emit Revealed(_account, mint.base + i);
		}
	}

	/**
	 * Abstract function called on each token when revealing
	 * @param _tokenId Token ID to reveal
	 * @param _seed Random number from VRF for the token
	 */
	function _revealToken(uint256 _tokenId, uint256 _seed) internal virtual;

	/**
	 * Set the VRF key hash
	 * @param _keyHash New keyHash
	 */
	function _setKeyHash(bytes32 _keyHash) internal {
		keyHash = _keyHash;
	}

	/**
	 * Set the VRF subscription ID
	 * @param _subscriptionId New subscriptionId
	 */
	function _setSubscriptionId(uint64 _subscriptionId) internal {
		subscriptionId = _subscriptionId;
	}

	/**
	 * Set the VRF callback gas limit
	 * @param _callbackGasLimit New callbackGasLimit
	 */
	function _setCallbackGasLimit(uint32 _callbackGasLimit) internal {
		callbackGasLimit = _callbackGasLimit;
	}

	/**
	 * @dev This empty reserved space is put in place to allow future versions to add new
	 * variables without shifting down storage in the inheritance chain.
	 * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
	 */
	uint256[45] private __gap;
}