// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./IOwnableInitializer.sol";
import "./Clones.sol";
import "./Context.sol";
import "./LibAccessControl.sol";
import "./LibCloner.sol";
import "./InitializableDiamond.sol";

/**
 * @title ClonerFacet
 * @author Limit Break, Inc.
 * @notice Clone Factory Facet for use in deploying general purpose ERC-1167 Minimal Proxy Clones
 * @notice See https://eips.ethereum.org/EIPS/eip-1167 for details.
 */
contract ClonerFacet is Context, InitializableDiamond {

    error ClonerFacet__CallerDoesNotHaveAdminRole();
    error ClonerFacet__CallerDoesNotHaveRole();
    error ClonerFacet__CannotGrantRoleToZeroAddress();
    error ClonerFacet__CannotTransferAdminRoleToSelf();
    error ClonerFacet__CannotTransferAdminRoleToZeroAddress();
    error ClonerFacet__InitializationArrayLengthMismatch();
    error ClonerFacet__InitializationArgumentInvalid(uint256 arrayIndex);
    error ClonerFacet__InitializationSelectorsRequired();

    ///@notice Value defining the `Cloner Admin Role`.
    bytes32 public constant CLONER_ADMIN_ROLE = keccak256("CLONER_ADMIN_ROLE");

    /// @dev Address of the Cloner facet - used for initialization and set in constructor
    /// @dev Since we're unable to reference the contract in address(this) due to delegate call, we use this constant
    address private immutable CLONER_ADDRESS;

    /// @notice Emitted when a new clone has been created
    event CloneCreated(address indexed referenceContractAddress, address indexed cloneAddress);

    constructor() {
        CLONER_ADDRESS = address(this);
    }

    /**
     * @notice Initializer function to ensure that clones are grant the correct admin role to the deployer
     *
     * @dev    <h4>Postconditions</h4>
     * @dev    1. `CLONER_ADMIN_ROLE` is granted to the `msg.sender`
     * @dev    2. `_initialized` is set to 1, preventing further initializations in the future.
     */
    function __ClonerFacet_init() public initializer(CLONER_ADDRESS) {
        LibAccessControl._setAdminRole(CLONER_ADMIN_ROLE, CLONER_ADMIN_ROLE);
        LibAccessControl._grantRole(CLONER_ADMIN_ROLE, _msgSender());
    }

    /**
     * @notice Allows the current contract admin to transfer the `Admin Role` to a new address.
     *
     * @dev    Throws if newAdmin is the zero-address
     * @dev    Throws if the caller is not the current admin.
     * @dev    Throws if the caller is an admin and tries to transfer admin to itself.
     *
     * @dev    <h4>Postconditions</h4>
     * @dev    1. The new admin has been granted the `Admin Role`.
     * @dev    2. The caller/former admin has had `Admin Role` revoked.
     *
     * @param  newAdmin Address of the new admin user.
     */
    function transferClonerAdminRole(address newAdmin) external {
        _requireCallerIsAdmin();

        if (newAdmin == address(0)) {
            revert ClonerFacet__CannotTransferAdminRoleToZeroAddress();
        }

        if (newAdmin == _msgSender()) {
            revert ClonerFacet__CannotTransferAdminRoleToSelf();
        }

        LibAccessControl._revokeRole(CLONER_ADMIN_ROLE, _msgSender());
        LibAccessControl._grantRole(CLONER_ADMIN_ROLE, newAdmin);
    }

    /**
     * @notice Allows the current contract admin to revoke the `Admin Role` from a user.
     *
     * @dev    Throws if the caller is not the current admin.
     *
     * @dev    <h4>Postconditions</h4>
     * @dev    1. The admin role has been revoked from the specified user.
     *
     * @param  admin Address of the user to revoke admin from.
     */
    function revokeClonerAdminRole(address admin) external {
        _requireCallerIsAdmin();

        LibAccessControl.revokeRole(CLONER_ADMIN_ROLE, admin);
    }

    /**
     * @notice Allows the current contract admin to revoke a role from a user.
     *
     * @dev    Throws if the caller is not the current admin.
     *
     * @dev    <h4>Postconditions</h4>
     * @dev    1. The role has been revoked from the specified user.
     *
     * @param  role Role to revoke from the user
     * @param  account Address of the user to revoke the role from.
     */
    function revokeRole(bytes32 role, address account) external {
        _requireCallerIsAdmin();

        LibAccessControl.revokeRole(role, account);
    }

    /**
     * @notice Allows the current contract admin to grant the `Admin Role` to a user.
     *
     * @dev    Throws if the caller is not the current admin.
     * @dev    Throws if the new admin is address zero.
     *
     * @dev    <h4>Postconditions</h4>
     * @dev    1. The admin role has been granted to the specified user.
     *
     * @param  admin Address of the user to grant admin to.
     */
    function grantClonerAdminRole(address admin) external {
        _requireCallerIsAdmin();

        if (admin == address(0)) {
            revert ClonerFacet__CannotTransferAdminRoleToZeroAddress();
        }

        LibAccessControl.grantRole(CLONER_ADMIN_ROLE, admin);
    }

    /**
     * @notice Allows the current contract admin to grant a role to a user.
     *
     * @dev    Throws if the caller is not the current admin.
     * @dev    Throws if the provided address is address zero.
     *
     * @dev    <h4>Postconditions</h4>
     * @dev    1. The role has been granted to the specified user.
     *
     * @param  role Role to grant the user
     * @param  account Address of the user to grant the role to.
     */
    function grantRole(bytes32 role, address account) external {
        _requireCallerIsAdmin();

        if (account == address(0)) {
            revert ClonerFacet__CannotGrantRoleToZeroAddress();
        }
        LibAccessControl.grantRole(role, account);
    }

    /**
     * @notice Deploys a new ERC-1167 Minimal Proxy Contract based on the provided reference contract.
     * @dev    The optional initialization selectors and arguments should be provided to atomically
     * @dev    initialize the deployed contract.  If no initialization is required, these can be empty arrays.
     *
     * @dev    Throws when the provided initializer selectors and args arrays are different lengths
     * @dev    Throws when invalid initializer arguments or selectors are provided
     * @dev    Throws when the contract does not support the `IOwnableInitializer` interface
     * @dev    Throws when the reference contract is not a whitelisted clonable contract
     * @dev      - This is to prevent phishing attacks using the cloner contract to deploy malicious contracts
     *
     * @dev    <h4>Postconditions</h4>
     * @dev    1. A new ERC-1167 Proxy has been cloned and initialized
     * @dev    2. The new contract is owned by the specified `contractOwner` value
     * @dev    3. A `CloneCreated` event has been emitted
     *
     * @param  referenceContract       Reference contract to clone
     * @param  contractOwner           Address that should be assigned ownership of the deployed clone contract
     * @param  initializationSelectors An array of 4 byte selectors to be called during initialization
     * @param  initializationArgs      An array of ABI encoded calldata to be used with the provided selectors
     */
    function cloneContract(
        address referenceContract,
        address contractOwner,
        bytes4[] calldata initializationSelectors,
        bytes[] calldata initializationArgs
    ) external returns (address) {
        LibCloner._requireIsWhitelisted(referenceContract);
        return _cloneContract(referenceContract, contractOwner, initializationSelectors, initializationArgs);
    }

    /**
     * @notice Deploys a new ERC-1167 Minimal Proxy Contract based on the provided reference contract.
     * @dev    The optional initialization selectors and arguments should be provided to atomically
     * @dev    initialize the deployed contract.  If no initialization is required, these can be empty arrays.
     *
     * @dev    Throws when the provided initializer selectors and args arrays are different lengths
     * @dev    Throws when invalid initializer arguments or selectors are provided
     * @dev    Throws when the contract does not support the `IOwnableInitializer` interface
     * @dev    Throws when the caller does not have the provided role assigned
     * @dev    Throws when the reference contract is not a whitelisted clonable contract
     * @dev      - This is to prevent phishing attacks using the cloner contract to deploy malicious contracts
     *
     * @dev    <h4>Postconditions</h4>
     * @dev    1. A new ERC-1167 Proxy has been cloned and initialized
     * @dev    2. The new contract is owned by the specified `contractOwner` value
     * @dev    3. A `CloneCreated` event has been emitted
     *
     * @param  referenceContract       Reference contract to clone
     * @param  contractOwner           Address that should be assigned ownership of the deployed clone contract
     * @param  role                    Role that the reference contract should be whitelisted for
     * @param  initializationSelectors An array of 4 byte selectors to be called during initialization
     * @param  initializationArgs      An array of ABI encoded calldata to be used with the provided selectors
     */
    function cloneRoleBasedContract(
        address referenceContract,
        address contractOwner,
        bytes32 role,
        bytes4[] calldata initializationSelectors,
        bytes[] calldata initializationArgs
    ) external returns (address) {
        _requireCallerHasRole(role);
        LibCloner._requireIsRoleBasedWhitelisted(keccak256(abi.encodePacked(role, referenceContract)));
        return _cloneContract(referenceContract, contractOwner, initializationSelectors, initializationArgs);
    }

    /**
     * @notice Initializes a new role with an admin role
     *
     * @dev    Throws if the caller is not the current cloner admin.
     *
     * @dev    <h4>Postconditions</h4>
     * @dev    1. The role is now initialized with the provided admin role
     *
     * @param  role      Role to setup
     * @param  adminRole Role that is the admin of the new role
     */
    function setupRole(bytes32 role, bytes32 adminRole) external {
        _requireCallerIsAdmin();
        LibAccessControl._setAdminRole(role, adminRole);
    }

    /**
     * @notice Whitelists a reference contract as a clonable contract
     *
     * @dev    Throws if the caller is not the current admin.
     * @dev    Throws if the reference contract does not contain code
     *
     * @dev    <h4>Postconditions</h4>
     * @dev    1. The reference contract is now whitelisted as a clonable contract
     *
     * @param  referenceContract Address of the reference contract to whitelist
     */
    function whitelistReferenceContract(address referenceContract) external {
        _requireCallerIsAdmin();
        LibCloner._whitelistReferenceContract(referenceContract);
    }

    /**
     * @notice Whitelists a reference contract as a clonable contract for a specific role
     *
     * @dev    Throws if the caller is not the current admin.
     * @dev    Throws if the reference contract does not contain code
     *
     * @dev    <h4>Postconditions</h4>
     * @dev    1. The reference contract is now whitelisted as a clonable contract for the specified role
     *
     * @param  referenceContract Address of the reference contract to whitelist
     * @param  role              Role that the reference contract should be whitelisted for
     */
    function whitelistRoleBasedReferenceContract(address referenceContract, bytes32 role) external {
        _requireCallerIsAdmin();
        LibCloner._whitelistRoleBasedReferenceContract(keccak256(abi.encodePacked(role, referenceContract)));
    }

    /**
     * @notice Deprecates a whitelisted reference contract
     *
     * @dev    Throws if the caller is not the current admin.
     * @dev    Throws if the reference contract is not whitelisted
     *
     * @dev    <h4>Postconditions</h4>
     * @dev    1. The reference contract is no longer whitelisted as a clonable contract
     *
     * @param  referenceContract Address of the reference contract to remove from the whitelist
     */
    function unwhitelistReferenceContract(address referenceContract) external {
        _requireCallerIsAdmin();
        LibCloner._unwhitelistReferenceContract(referenceContract);
    }

    /**
     * @notice Deprecates a whitelisted reference contract
     *
     * @dev    Throws if the caller is not the current admin.
     * @dev    Throws if the reference contract is not whitelisted
     *
     * @dev    <h4>Postconditions</h4>
     * @dev    1. The reference contract is no longer whitelisted as a clonable contract
     *
     * @param  referenceContract Address of the reference contract to remove from the whitelist
     */
     function unwhitelistRoleBasedReferenceContract(address referenceContract, bytes32 role) external {
        _requireCallerIsAdmin();
        LibCloner._unwhitelistRoleBasedReferenceContract(keccak256(abi.encodePacked(role, referenceContract)));
    }

    /// @notice Returns if the provided account is assigned the `CLONER_ADMIN_ROLE`
    function isClonerAdmin(address account) external view returns (bool) {
        return LibAccessControl.hasRole(CLONER_ADMIN_ROLE, account);
    }

    /// @notice Returns if the provided account is assigned the provided role
    function hasRole(bytes32 role, address account) external view returns (bool) {
        return LibAccessControl.hasRole(role, account);
    }

    /// @notice Returns if the provided reference contract is whitelisted as a clonable contract
    /// @notice If a role is provided, the return value will indicate if the reference contract is whitelisted for that role
    /// @notice If a 0 value is provided for role, the return value will indicate if the reference contract is publicly whitelisted
    function isWhitelistedReferenceContract(address referenceContract, bytes32 role) external view returns (bool) {
        if (role != bytes32(0)) {
            return LibCloner._isRoleBasedWhitelisted(keccak256(abi.encodePacked(role, referenceContract)));
        }
        return LibCloner._isWhitelisted(referenceContract);
    }

    /// @dev Validates that the msg.sender has the `CLONER_ADMIN_ROLE` assigned.
    function _requireCallerIsAdmin() internal view {
        if (!LibAccessControl.hasRole(CLONER_ADMIN_ROLE, _msgSender())) {
            revert ClonerFacet__CallerDoesNotHaveAdminRole();
        }
    }

    function _requireCallerHasRole(bytes32 role) internal view {
        if (!LibAccessControl.hasRole(role, _msgSender())) {
            revert ClonerFacet__CallerDoesNotHaveRole();
        }
    }

    /// @dev Validates that the provided array lengths are the same.
    function _requireArrayLengthsMatch(uint256 arrayLength1, uint256 arrayLength2) internal pure {
        if (arrayLength1 != arrayLength2) {
            revert ClonerFacet__InitializationArrayLengthMismatch();
        }
    }

    function _cloneContract(
        address referenceContract,
        address contractOwner,
        bytes4[] calldata initializationSelectors,
        bytes[] calldata initializationArgs
    ) internal returns (address) {
        uint256 initializationSelectorsLength = initializationSelectors.length;
        if (initializationSelectorsLength == 0) {
            revert ClonerFacet__InitializationSelectorsRequired();
        }
        _requireArrayLengthsMatch(initializationSelectorsLength, initializationArgs.length);

        address clone = Clones.clone(referenceContract);

        emit CloneCreated(referenceContract, clone);

        IOwnableInitializer(clone).initializeOwner(address(this));

        for (uint256 i = 0; i < initializationSelectorsLength;) {
            (bool success,) = clone.call(abi.encodePacked(initializationSelectors[i], initializationArgs[i]));

            if (!success) {
                revert ClonerFacet__InitializationArgumentInvalid(i);
            }

            unchecked {
                ++i;
            }
        }

        IOwnableInitializer(clone).transferOwnership(contractOwner);

        return clone;
    }
}
