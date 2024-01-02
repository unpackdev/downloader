// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Importing OpenZeppelin's Access Control and Registry Interface
import "./AccessControlEnumerableUpgradeable.sol";
import "./IRegistry.sol";
import "./IIDRegistry.sol";
import "./IService.sol";

/**
 * @title IDRegistry
 * @dev Manages a registry of whitelisted addresses for various compliances.
 */
contract IDRegistry is AccessControlEnumerableUpgradeable {
    // Reference to the IRegistry contract for accessing registry functionalities
    IRegistry registry;

    // Constant for compliance admin role
    bytes32 public constant COMPLIANCE_ADMIN = keccak256("COMPLIANCE_ADMIN");

    // Mapping from compliance identifiers to a mapping of addresses to their whitelisted status
    mapping(bytes32 => mapping(address => bool)) private _whitelists;

    // Events for logging important actions
    event ComplianceAdminAdded(
        address indexed admin,
        bytes32 indexed compliance
    );
    event ComplianceAdminRemoved(
        address indexed admin,
        bytes32 indexed compliance
    );
    event Whitelisted(
        address indexed account,
        bytes32 indexed compliance,
        bool status
    );

    // Modifier to restrict function access to only super admins
    modifier onlySuperAdmin() {
        require(
            IService(registry.service()).hasRole(
                IService(registry.service()).ADMIN_ROLE(),
                msg.sender
            ),
            "IDRegistry: Caller is not a super admin"
        );
        _;
    }

    // Modifier to restrict function access to only compliance admins of a specific compliance
    modifier onlyComplianceAdmin(bytes32 compliance) {
        require(
            IService(registry.service()).hasRole(
                IService(registry.service()).SERVICE_MANAGER_ROLE(),
                msg.sender
            ) ||
                (hasRole(COMPLIANCE_ADMIN, msg.sender) &&
                    hasRole(compliance, msg.sender)),
            "IDRegistry: Caller is not a compliance admin"
        );
        _;
    }

    // Constructor to disable initializer for the upgradeable contract pattern
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initializer function, can only be called once
     * @param registry_ Address of the Registry contract
     */
    function initialize(IRegistry registry_) external initializer {
        registry = registry_;
    }

    /**
     * @dev Adds a compliance admin for a specific compliance
     * @param admin Address of the new compliance admin
     * @param compliance Compliance identifier
     */
    function addComplianceAdmin(
        address admin,
        bytes32 compliance
    ) public onlySuperAdmin {
        _grantRole(COMPLIANCE_ADMIN, admin);
        _grantRole(compliance, admin);
        emit ComplianceAdminAdded(admin, compliance);
    }

    /**
     * @dev Removes a compliance admin for a specific compliance
     * @param admin Address of the compliance admin to be removed
     * @param compliance Compliance identifier
     */
    function removeComplianceAdmin(
        address admin,
        bytes32 compliance
    ) public onlySuperAdmin {
        _revokeRole(COMPLIANCE_ADMIN, admin);
        _revokeRole(compliance, admin);
        emit ComplianceAdminRemoved(admin, compliance);
    }

    /**
     * @dev Adds multiple addresses to the whitelist for a specific compliance.
     * @param accounts Array of addresses to be whitelisted.
     * @param compliance Compliance identifier.
     */
    function addToWhitelist(
        address[] calldata accounts,
        bytes32 compliance
    ) public onlyComplianceAdmin(compliance) {
        for (uint256 i = 0; i < accounts.length; i++) {
            _whitelists[compliance][accounts[i]] = true;
        }
        registry.log(
            _msgSender(),
            address(this),
            0,
            abi.encodeWithSelector(
                IIDRegistry.addToWhitelist.selector,
                accounts,
                compliance
            )
        );
    }

    /**
     * @dev Removes multiple addresses from the whitelist for a specific compliance.
     * @param accounts Array of addresses to be removed from the whitelist.
     * @param compliance Compliance identifier.
     */
    function removeFromWhitelist(
        address[] calldata accounts,
        bytes32 compliance
    ) public onlyComplianceAdmin(compliance) {
        for (uint256 i = 0; i < accounts.length; i++) {
            _whitelists[compliance][accounts[i]] = false;
        }
        registry.log(
            _msgSender(),
            address(this),
            0,
            abi.encodeWithSelector(
                IIDRegistry.removeFromWhitelist.selector,
                accounts,
                compliance
            )
        );
    }

    /**
     * @dev Checks if an address is associated with service contracts
     * @param account Address to check
     * @return True if the address is a service contract, false otherwise
     */
    function isServiceContract(address account) public view returns (bool) {
        return
            registry.typeOf(account) != IRecordsRegistry.ContractType.None ||
            address(registry.service().vesting()) == account ||
            address(registry.service()) == account ||
            address(registry.service().tgeFactory()) == account ||
            address(registry.service().tokenFactory()) == account ||
            address(0) == account;
    }

    /**
     * @dev Checks if an address is whitelisted for a specific compliance
     * @param account Address to check the whitelist status for
     * @param compliance Compliance identifier
     * @return True if the address is whitelisted or if the compliance identifier is zero bytes
     */
    function isWhitelisted(
        address account,
        bytes32 compliance
    ) public view returns (bool) {
        return
            compliance == bytes32(0) ||
            isServiceContract(account) ||
            _whitelists[compliance][account];
    }
}
