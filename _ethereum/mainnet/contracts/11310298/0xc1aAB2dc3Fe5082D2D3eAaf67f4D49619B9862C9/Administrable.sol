pragma solidity 0.6.6;

import "./IAdmin.sol";
import "./GSNable.sol";


/**
 * @author Simon Dosch
 * @title Administrable
 * @dev Manages roles for all inheriting contracts
 */
contract Administrable is IAdmin, GSNable {
	/**
     * @dev list of standard roles
     * roles can be added (i.e. for constraint modules)
     *
     * --main roles--
     * ADMIN   (can add and remove roles)
     * CONTROLLER (ERC1400, can force-transfer tokens if contract _isControllable)
     * ISSUER (ISSUER)
     * REDEEMER (BURNER, can redeem tokens, their own OR others IF _isOperatorForPartition())
     * MODULE_EDITOR (can edit constraint modules),
     *
     * --additional roles--
     * DOCUMENT_EDITOR
     * CAP_EDITOR

     * --constraint module roles--
     * PAUSER
     * WHITELIST_EDITOR
     * TIME_LOCK_EDITOR
     * SPENDING_LIMITS_EDITOR
     * VESTING_PERIOD_EDITOR
     * GSN_CONTROLLER
     * DEFAULT_PARTITIONS_EDITOR
	 *
	 * ...
     */

	// EVENTS in IAdmin.sol

	/**
	 * @dev Modifier to make a function callable only when the caller is a specific role.
	 */
	modifier onlyRole(bytes32 role) {
		require(hasRole(role, _msgSender()), "unauthorized");
		_;
	}

	/**
	 * @param role Role that is being assigned
	 * @param account The address that is being assigned a role
	 * @dev Assigns a role to an account
	 * only ADMIN
	 */
	function addRole(bytes32 role, address account)
		public
		override
		onlyRole(bytes32("ADMIN"))
	{
		_add(role, account);
	}

	/**
	 * @param roles Roles that are being assigned
	 * @param accounts The addresses that are being assigned a role
	 * @dev Assigns a bulk of roles to accounts
	 * only ADMIN
	 */
	function bulkAddRole(bytes32[] memory roles, address[] memory accounts)
		public
		override
		onlyRole(bytes32("ADMIN"))
	{
		require(roles.length <= 100, "too many roles");
		require(roles.length == accounts.length, "length");
		for (uint256 i = 0; i < roles.length; i++) {
			_add(roles[i], accounts[i]);
		}
	}

	/**
	 * @param role Role that is being removed
	 * @param account The address that a role is removed from
	 * @dev Removes a role from an account
	 * only ADMIN
	 */
	function removeRole(bytes32 role, address account)
		public
		override
		onlyRole(bytes32("ADMIN"))
	{
		_remove(role, account);
	}

	/**
	 * @param role Role that is being renounced by the _msgSender()
	 * @dev Removes a role from the sender's address
	 * ATTENTION: it is possible to remove the last ADMINN role by renouncing it!
	 */
	function renounceRole(bytes32 role) public override {
		_remove(role, _msgSender());

		emit RoleRenounced(role, _msgSender());
	}

	/**
	 * @dev check if an account has a role
	 * @return bool True if account has role
	 */
	function hasRole(bytes32 role, address account)
		public
		override
		view
		returns (bool)
	{
		return _roles[role][account];
	}

	/******* INTERNAL FUNCTIONS *******/

	/**
	 * @dev give an account access to a role
	 */
	function _add(bytes32 role, address account) internal {
		require(!hasRole(role, account), "already has role");

		_roles[role][account] = true;

		emit RoleGranted(role, account, _msgSender());
	}

	/**
	 * @dev remove an account's access to a role
	 * cannot remove own ADMIN role
	 * address must have role
	 */
	function _remove(bytes32 role, address account) internal {
		require(hasRole(role, account), "does not have role");

		_roles[role][account] = false;

		emit RoleRevoked(role, account, _msgSender());
	}
}
