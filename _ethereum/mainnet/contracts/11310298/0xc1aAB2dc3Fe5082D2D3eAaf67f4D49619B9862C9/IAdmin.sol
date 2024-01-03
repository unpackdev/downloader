pragma solidity 0.6.6;


/**
 * @author Simon Dosch
 * @title IAdmin
 * @dev Administrable interface
 */
interface IAdmin {
	/**
	 * @param role Role that is being assigned
	 * @param account The address that is being assigned a role
	 * @dev Assigns a role to an account
	 * only ADMIN
	 */
	function addRole(bytes32 role, address account) external;

	/**
	 * @param roles Roles that are being assigned
	 * @param accounts The addresses that are being assigned a role
	 * @dev Assigns a bulk of roles to accounts
	 * only ADMIN
	 */
	function bulkAddRole(bytes32[] calldata roles, address[] calldata accounts)
		external;

	/**
	 * @param role Role that is being removed
	 * @param account The address that a role is removed from
	 * @dev Removes a role from an account
	 * only ADMIN
	 */
	function removeRole(bytes32 role, address account) external;

	/**
	 * @param role Role that is being renounced by the _msgSender()
	 * @dev Removes a role from the sender's address
	 */
	function renounceRole(bytes32 role) external;

	/**
	 * @dev check if an account has a role
	 * @return bool True if account has role
	 */
	function hasRole(bytes32 role, address account)
		external
		view
		returns (bool);

	/**
	 * @dev Emitted when `account` is granted `role`.
	 *
	 * `sender` is the account that originated the contract call, an admin role
	 * bearer except when using {_setupRole}.
	 */
	event RoleGranted(
		bytes32 indexed role,
		address indexed account,
		address indexed sender
	);

	/**
	 * @dev Emitted when `account` is revoked `role`.
	 *
	 * `sender` is the account that originated the contract call:
	 *   - if using `revokeRole`, it is the admin role bearer
	 *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
	 */
	event RoleRevoked(
		bytes32 indexed role,
		address indexed account,
		address indexed sender
	);

	/**
	 * @dev Emitted whenever an account renounced a role
	 */
	event RoleRenounced(bytes32 indexed role, address indexed account);
}
