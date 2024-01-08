// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./AccessControl.sol";
import "./AccessControl.sol";

/**
 * @title Access Control List Extension Interface
 *
 * @notice External interface of AccessExtension declared to support ERC165 detection.
 *      See Access Control List Extension documentation below.
 *
 * @author Basil Gorin
 */
interface IAccessExtension is IAccessControl {
	function removeFeature(bytes32 feature) external;
	function addFeature(bytes32 feature) external;
	function isFeatureEnabled(bytes32 feature) external view returns(bool);
}

/**
 * @title Access Control List Extension
 *
 * @notice Access control smart contract provides an API to check
 *      if specific operation is permitted globally and/or
 *      if particular user has a permission to execute it.
 *
 * @notice It deals with two main entities: features and roles.
 *
 * @notice Features are designed to be used to enable/disable specific
 *      functions (public functions) of the smart contract for everyone.
 * @notice User roles are designed to restrict access to specific
 *      functions (restricted functions) of the smart contract to some users.
 *
 * @notice Terms "role", "permissions" and "set of permissions" have equal meaning
 *      in the documentation text and may be used interchangeably.
 * @notice Terms "permission", "single permission" implies only one permission set.
 *
 * @dev OpenZeppelin AccessControl based implementation. Features are stored as
 *      "self"-roles: feature is a role assigned to the smart contract itself
 *
 * @dev Automatically assigns the deployer an admin permission
 *
 * @dev This smart contract is designed to be inherited by other
 *      smart contracts which require access control management capabilities.
 *
 * @author Basil Gorin
 */
contract AccessExtension is IAccessExtension, AccessControl {
	constructor() {
		// setup admin role for smart contract deployer initially
		_setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
	}

	/**
	 * @inheritdoc IERC165
	 */
	function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
		// reconstruct from current interface and super interface
		return interfaceId == type(IAccessExtension).interfaceId || super.supportsInterface(interfaceId);
	}

	/**
	 * @notice Removes the feature from the set of the globally enabled features,
	 *      taking into account sender's permissions
	 *
	 * @dev Requires transaction sender to have a permission to set the feature requested
	 *
	 * @param feature a feature to disable
	 */
	function removeFeature(bytes32 feature) public override {
		// delegate to Zeppelin's `revokeRole`
		revokeRole(feature, address(this));
	}

	/**
	 * @notice Adds the feature to the set of the globally enabled features,
	 *      taking into account sender's permissions
	 *
	 * @dev Requires transaction sender to have a permission to set the feature requested
	 *
	 * @param feature a feature to enable
	 */
	function addFeature(bytes32 feature) public override {
		// delegate to Zeppelin's `grantRole`
		grantRole(feature, address(this));
	}

	/**
	 * @notice Checks if requested feature is enabled globally on the contract
	 *
	 * @param feature the feature to check
	 * @return true if the feature requested is enabled, false otherwise
	 */
	function isFeatureEnabled(bytes32 feature) public override view returns(bool) {
		// delegate to Zeppelin's `hasRole`
		return hasRole(feature, address(this));
	}

	/**
 * @notice Checks if transaction sender `msg.sender` has the role required
 *
 * @param role the role to check against
 * @return true if sender has the role required, false otherwise
 */
	function isSenderInRole(bytes32 role) public view returns(bool) {
		// delegate call to `isOperatorInRole`, passing transaction sender
		return hasRole(role, _msgSender());
	}

}
