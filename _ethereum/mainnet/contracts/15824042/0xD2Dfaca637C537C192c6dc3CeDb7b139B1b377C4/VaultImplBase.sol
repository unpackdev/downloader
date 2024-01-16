//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./draft-IERC1822.sol";
import "./ERC1967Upgrade.sol";
import "./AccessControl.sol";

/**
 * @notice Base logic for the Implementation.
 * @dev The actual Implementation must derive from this contract and override `_initialize` and `_migrate` methods if necessary.
 */
abstract contract VaultImplBase is IERC1822Proxiable, ERC1967Upgrade, AccessControl {
	// ======================
	// VaultImplBase specific
	// ======================

	bytes32 public constant MAINTAINER_ROLE = keccak256('MAINTAINER_ROLE');

	/**
	 * @notice Set the Implementation deployer as an Admin and Maintainer.
	 */
	constructor() {
		_setupDeployerRoles();
	}

	address private immutable __self = address(this);

	/**
	 * @notice Check that the execution is being performed through a delegatecall call and that the execution context is
	 * a proxy contract with an implementation (as defined in ERC1967) pointing to self.
	 */
	modifier onlyProxy() {
		require(address(this) != __self, 'Must be called through delegatecall');
		require(_getImplementation() == __self, 'Must be called through active proxy');
		_;
	}

	/**
	 * @notice Check that the execution is not being performed through a delegate call. This allows a function to be
	 * callable on the implementing contract but not through proxies.
	 */
	modifier notDelegated() {
		require(address(this) == __self, 'Must not be called through delegatecall');
		_;
	}

	/**
	 * @notice Check that the caller has MAINTAINER_ROLE.
	 * @dev Role differs depending on the caller. If called via Proxy, then Proxy's storage is checked.
	 * If called directly, this contract's storage is checked. This logic allows to have a different Proxy and Implementation roles.
	 */
	modifier onlyMaintainer() {
		require(AccessControl.hasRole(MAINTAINER_ROLE, msg.sender), 'Caller not maintainer');
		_;
	}

	// ======================
	// Caller-specific storage
	// ======================

	/**
	 * @notice Grant DEFAULT_ADMIN_ROLE and MAINTAINER_ROLE to the caller. Internal method.
	 * @dev Grant DEFAULT_ADMIN_ROLE and MAINTAINER_ROLE to the caller. Internal method.
	 */
	function _setupDeployerRoles() internal {
		AccessControl._grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
		AccessControl._grantRole(MAINTAINER_ROLE, msg.sender);
	}

	// ======================
	// Implementation context storage
	// ======================
	/**
	 * @dev Indicates that a next implementation address was set.
	 * @param nextImplementation Address of a next implementation that was set.
	 */
	event NextImplementationSet(VaultImplBase indexed nextImplementation);

	/** @dev Double underscore enables using the same variable name with a single underscore in a derived contract */
	VaultImplBase private __nextImplementation;

	/**
	 * @notice Return next implementation contract address or zero address if not set yet.
	 * NextImplementation points to the next implementation contract in a chain of contracts to allow upgrading.
	 * @dev Must not be a delegated call.
	 * @return VaultImplBase Next implementation contract address or zero address if not set yet.
	 */
	function getNextImplementation() external view notDelegated returns (VaultImplBase) {
		return __nextImplementation;
	}

	/**
	 * @notice Set next implementation contract address if not set yet.
	 * NextImplementation points to the next implementation contract in a chain of contracts to allow upgrading.
	 * @dev Must not be a delegated call. Require caller to be Implementation Maintainer. Must not be zero address or self address.
	 * Emits `NextImplementationSet` event.
	 * @param nextImplementation Next implementation contract address.
	 */
	function setNextImplementation(VaultImplBase nextImplementation)
		external
		notDelegated
		onlyMaintainer
	{
		require(address(__nextImplementation) == address(0), 'nextImplementation is already set');
		// prevent unnecessary event emissions & infinite nextImplementation chain
		require(
			address(nextImplementation) != address(0) && address(nextImplementation) != __self,
			'Invalid nextImplementation supplied'
		);

		__nextImplementation = nextImplementation;

		emit NextImplementationSet(nextImplementation);
	}

	/**
	 * @dev Implementation of the ERC1822 function. This returns the storage slot used by the
	 * implementation. It is used to validate the implementation's compatibility when performing an upgrade.
	 */
	function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
		return ERC1967Upgrade._IMPLEMENTATION_SLOT;
	}

	// ======================
	// Proxy context storage
	// ======================
	bool private __initialized;
	bool private __migrated;

	/**
	 * @notice Override this function for Implementation to initialize any storage variables. Use instead of constructor.
	 * @dev Can only be called by Proxy.
	 */
	function _initialize() internal virtual onlyProxy {}

	/**
	 * @notice Call `_initialize_ defined by the Implementation to initialize any storage variables.
	 * @dev Can only be called by Proxy.
	 */
	function initialize() external onlyProxy {
		require(__initialized == false, 'Already initialized');
		__initialized = true;
		__migrated = true;
		_setupDeployerRoles();
		_initialize();
	}

	/**
	 * @notice Override this function for Implementation to migrate any storage variables between different implementation versions if needed.
	 * @dev Can only be called by Proxy.
	 */
	function _migrate() internal virtual onlyProxy {}

	/**
	 * @notice Call `_migrate` defined by the Implementation to migrate any storage variables. Call `upgrade` function on itself to ensure the this contract is the latest version.
	 * @dev Can only be called by Proxy.
	 */
	function applyUpgrade() external onlyProxy {
		require(__migrated == false, 'Already migrated');
		__migrated = true;
		_migrate();

		if (address(VaultImplBase(_getImplementation()).getNextImplementation()) != address(0)) {
			// do recursive upgrade
			upgrade();
		}
	}

	/**
	 * @notice Perform an upgrade from the current implementation contract to a next one specified in a current Implementation. Also calls `applyUpgrade` on a next implementation.
	 * @dev Require called to be Proxy Maintainer. Can only be called by Proxy.
	 */
	function upgrade() public onlyMaintainer onlyProxy {
		VaultImplBase nextImplementation = VaultImplBase(_getImplementation())
			.getNextImplementation();

		if (address(nextImplementation) == address(0)) {
			revert('No next implementation to upgrade to');
		}

		__migrated = false;
		_upgradeToAndCallUUPS(
			address(nextImplementation),
			abi.encodeWithSelector(bytes4(keccak256('applyUpgrade()'))),
			true
		);
	}
}
