// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

import "./Registry.sol";
import "./DSAuthority.sol";

/// @title Authority contract managing proxy permissions
/// @notice Proxy will ask Authority for permission to execute received message if not initiated directly by the proxy owner.
contract Authority is DSAuthority {

	/// @notice Registry Stargate ID
	bytes32 private constant STARGATE_ID = keccak256("Stargate");

	/// @notice APUS registry address
	address public immutable registry;


	constructor(address _registry) {
		registry = _registry;
	}


	/// @notice Called by proxy to determine if sender is allowed to make a message call.
	/// @dev Currently are allowed only messages from Stargate, initiated directly by the proxy owner, or initiated from within Proxy.
	/// @dev Authority contract cannot forbid proxy owner from calling arbitrary messages.
	function canCall(address src, address /* dst */, bytes4 /* sig */) override public view returns (bool) {
		return src == Registry(registry).getAddress(STARGATE_ID);
	}

}
