// SPDX-License-Identifier: MPL-2.0
pragma solidity 0.8.4;

import "./PausableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./IMarketBehavior.sol";
import "./IMarket.sol";

contract YouTubeMarket is
	IMarketBehavior,
	PausableUpgradeable,
	AccessControlUpgradeable
{
	address public associatedMarket;
	mapping(address => string) private repositories;
	mapping(bytes32 => address) private metrics;
	mapping(bytes32 => address) private properties;
	mapping(bytes32 => address) private markets;
	mapping(bytes32 => bool) private pendingAuthentication;

	// ROLE
	bytes32 public constant KHAOS_ROLE = keccak256("KHAOS_ROLE");

	// event
	event Registered(address _metrics, string _repository);
	event Authenticated(string _repository, uint256 _status, string message);
	event Query(string youtubeChannel, string publicSignature, address account);

	function initialize() external initializer {
		__AccessControl_init();
		__Pausable_init();
		_setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
		_setRoleAdmin(KHAOS_ROLE, DEFAULT_ADMIN_ROLE);
		_setupRole(KHAOS_ROLE, _msgSender());
	}

	/*
    _youtubeChannel: ex)
                        YouTube channel id: UCN7m74tFgJJnoGL4zk6aJ6g
    _publicSignature: signature string(created by Khaos)
    */
	function authenticate(
		address _prop,
		string memory _youtubeChannel,
		string memory _publicSignature,
		string memory,
		string memory,
		string memory,
		address _dest,
		address account
	) external override whenNotPaused returns (bool) {
		require(msg.sender == associatedMarket, "invalid sender");

		bytes32 key = createKey(_youtubeChannel);
		emit Query(_youtubeChannel, _publicSignature, account);
		properties[key] = _prop;
		markets[key] = _dest;
		pendingAuthentication[key] = true;
		return true;
	}

	function khaosCallback(
		string memory _youtubeChannel,
		uint256 _status,
		string memory _message
	) external whenNotPaused {
		require(
			hasRole(DEFAULT_ADMIN_ROLE, msg.sender) ||
				hasRole(KHAOS_ROLE, msg.sender),
			"illegal access"
		);
		require(_status == 0, _message);
		bytes32 key = createKey(_youtubeChannel);
		require(pendingAuthentication[key], "not while pending");
		emit Authenticated(_youtubeChannel, _status, _message);
		register(key, _youtubeChannel, properties[key]);
	}

	function register(
		bytes32 _key,
		string memory _repository,
		address _property
	) private {
		address _metrics = IMarket(associatedMarket).authenticatedCallback(
			_property,
			_key
		);
		repositories[_metrics] = _repository;
		metrics[_key] = _metrics;
		emit Registered(_metrics, _repository);
	}

	function createKey(string memory _repository)
		private
		pure
		returns (bytes32)
	{
		return keccak256(abi.encodePacked(_repository));
	}

	function getId(address _metrics)
		external
		view
		override
		returns (string memory)
	{
		return repositories[_metrics];
	}

	function getMetrics(string memory _repository)
		external
		view
		override
		returns (address)
	{
		return metrics[createKey(_repository)];
	}

	function addKhaosRole(address _khaos)
		external
		onlyRole(DEFAULT_ADMIN_ROLE)
	{
		_setupRole(KHAOS_ROLE, _khaos);
	}

	function deleteKhaosRole(address _khaos)
		external
		onlyRole(DEFAULT_ADMIN_ROLE)
	{
		revokeRole(KHAOS_ROLE, _khaos);
	}

	function setAssociatedMarket(address _associatedMarket)
		external
		onlyRole(DEFAULT_ADMIN_ROLE)
	{
		associatedMarket = _associatedMarket;
	}

	function name() external pure returns (string memory) {
		return "YouTube";
	}

	function schema() external pure override returns (string memory) {
		return
			// solhint-disable-next-line quotes
			'["YouTube Channel (e.g, UCN7m74tFgJJnoGL4zk6aJ6g)", "Khaos Public Signature"]';
	}

	function pause() external onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
		_pause();
	}

	function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) whenPaused {
		_unpause();
	}
}
