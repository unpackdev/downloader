// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./UUPSUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";

import "./IWhitelistManager.sol";

import "./errors.sol";

contract WhitelistManager is OwnableUpgradeable, PausableUpgradeable, UUPSUpgradeable {
    /*///////////////////////////////////////////////////////////////
                            Constants
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant CLIENT_DOMESTIC_FEEDER = keccak256("CLIENT_DOMESTIC_FEEDER_ROLE");
    bytes32 public constant CLIENT_INTERNATIONAL_FEEDER = keccak256("CLIENT_INTERNATIONAL_FEEDER_ROLE");

    bytes32 public constant CLIENT_DOMESTIC_SDYF = keccak256("CLIENT_DOMESTIC_SDYF_ROLE");
    bytes32 public constant CLIENT_INTERNATIONAL_SDYF = keccak256("CLIENT_INTERNATIONAL_SDYF_ROLE");

    bytes32 public constant LP_ROLE = keccak256("LP_ROLE");
    bytes32 public constant VAULT_ROLE = keccak256("VAULT_ROLE");
    bytes32 public constant OTC_ROLE = keccak256("OTC_ROLE");
    bytes32 public constant SYSTEM_ROLE = keccak256("SYSTEM_ROLE");

    /*///////////////////////////////////////////////////////////////
                            State Variables V1
    //////////////////////////////////////////////////////////////*/

    address public sanctionsOracle;

    mapping(bytes32 => mapping(address => bool)) public permissions;

    /*///////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/

    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /*///////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/

    constructor() {}

    /*///////////////////////////////////////////////////////////////
                            Initializer
    //////////////////////////////////////////////////////////////*/

    function initialize(address _owner) external initializer {
        if (_owner == address(0)) revert BadAddress();

        _transferOwnership(_owner);
        __Pausable_init();
    }

    /*///////////////////////////////////////////////////////////////
                    Override Upgrade Permission
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Upgradable by the owner.
     *
     */
    function _authorizeUpgrade(address /*newImplementation*/ ) internal view override {
        _checkOwner();
    }

    /*///////////////////////////////////////////////////////////////
                            External Functions
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Sets the new oracle address
     * @param _sanctionsOracle is the address of the new oracle
     */
    function setSanctionsOracle(address _sanctionsOracle) external {
        _checkOwner();

        if (_sanctionsOracle == address(0)) revert BadAddress();

        sanctionsOracle = _sanctionsOracle;
    }

    /**
     * @notice Checks if customer has been whitelisted
     * @dev DEPRECATED
     * @param _address the address of the account
     * @return value returning if allowed to transact
     */
    function isCustomer(address _address) external view returns (bool) {
        return isClient(_address);
    }

    /**
     * @notice Checks if client has been whitelisted
     * @param _address the address of the account
     * @return value returning if allowed to transact
     */
    function isClient(address _address) public view returns (bool) {
        if (_sanctioned(_address)) return false;

        if (_hasRole(CLIENT_DOMESTIC_FEEDER, _address)) return true;
        if (_hasRole(CLIENT_INTERNATIONAL_FEEDER, _address)) return true;
        // checking international first because domestic is never used
        if (_hasRole(CLIENT_INTERNATIONAL_SDYF, _address)) return true;
        if (_hasRole(CLIENT_DOMESTIC_SDYF, _address)) return true;

        return false;
    }

    /**
     * @notice Checks if client feeder has been whitelisted
     * @param _address the address of the account
     * @return value returning if allowed to transact
     */
    function isClientFeeder(address _address) external view returns (bool) {
        if (_sanctioned(_address)) return false;

        if (_hasRole(CLIENT_DOMESTIC_FEEDER, _address)) return true;
        if (_hasRole(CLIENT_INTERNATIONAL_FEEDER, _address)) return true;

        return false;
    }

    /**
     * @notice Checks if client domestic feeder has been whitelisted
     * @param _address the address of the account
     * @return value returning if allowed to transact
     */
    function isClientDomesticFeeder(address _address) external view returns (bool) {
        return _hasRoleAndNotSanctioned(CLIENT_DOMESTIC_FEEDER, _address);
    }

    /**
     * @notice Checks if client international feeder has been whitelisted
     * @param _address the address of the account
     * @return value returning if allowed to transact
     */
    function isClientInternationalFeeder(address _address) external view returns (bool) {
        return _hasRoleAndNotSanctioned(CLIENT_INTERNATIONAL_FEEDER, _address);
    }

    /**
     * @notice Checks if client sdyf has been whitelisted
     * @param _address the address of the account
     * @return value returning if allowed to transact
     */
    function isClientSDYF(address _address) external view returns (bool) {
        if (_sanctioned(_address)) return false;
        // checking international first because domestic is never used
        if (_hasRole(CLIENT_INTERNATIONAL_SDYF, _address)) return true;
        if (_hasRole(CLIENT_DOMESTIC_SDYF, _address)) return true;

        return false;
    }

    /**
     * @notice Checks if client domestic sdyf has been whitelisted
     * @param _address the address of the account
     * @return value returning if allowed to transact
     */
    function isClientDomesticSDYF(address _address) external view returns (bool) {
        return _hasRoleAndNotSanctioned(CLIENT_DOMESTIC_SDYF, _address);
    }

    /**
     * @notice Checks if client international sdyf has been whitelisted
     * @param _address the address of the account
     * @return value returning if allowed to transact
     */
    function isClientInternationalSDYF(address _address) external view returns (bool) {
        return _hasRoleAndNotSanctioned(CLIENT_INTERNATIONAL_SDYF, _address);
    }

    /**
     * @notice Checks if LP has been whitelisted
     * @param _address the address of the LP Wallet
     * @return value returning if allowed to transact
     */
    function isLP(address _address) external view returns (bool) {
        return _hasRoleAndNotSanctioned(LP_ROLE, _address);
    }

    /**
     * @notice Checks if System or Vault has been whitelisted
     * @param _address the address of the Vault
     * @return value returning if allowed to transact
     */
    function isSystemOrVault(address _address) external view returns (bool) {
        if (_hasRole(SYSTEM_ROLE, _address)) return true;
        if (_hasRole(VAULT_ROLE, _address)) return true;

        return false;
    }

    /**
     * @notice Checks if Vault has been whitelisted
     * @param _address the address of the Vault
     * @return value returning if allowed to transact
     */
    function isVault(address _address) external view returns (bool) {
        return _hasRole(VAULT_ROLE, _address);
    }

    /*
     * @notice Checks if OTC has been whitelisted
     * @param _address the address of the OTC
     * @return value returning if allowed to transact
     */
    function isOTC(address _address) external view returns (bool) {
        return _hasRoleAndNotSanctioned(OTC_ROLE, _address);
    }

    /*
     * @notice Checks if Smart Contract has been whitelisted
     * @param _address the address of the contract
     * @return value returning if allowed to transact
     */
    function isSystem(address _address) external view returns (bool) {
        return _hasRole(SYSTEM_ROLE, _address);
    }

    /**
     * @notice Checks if address has been whitelisted
     * @param _address the address
     * @return value returning if allowed to transact
     */
    function isAllowed(address _address) public view returns (bool) {
        // Vaults / Systems are internal,
        // realistically they would not be sanctioned
        if (_hasRole(VAULT_ROLE, _address)) return true;
        if (_hasRole(SYSTEM_ROLE, _address)) return true;

        if (_sanctioned(_address)) return false;

        if (_hasRole(CLIENT_DOMESTIC_FEEDER, _address)) return true;
        if (_hasRole(CLIENT_INTERNATIONAL_FEEDER, _address)) return true;
        if (_hasRole(CLIENT_INTERNATIONAL_SDYF, _address)) return true;
        // checking international first because domestic is never used
        if (_hasRole(CLIENT_DOMESTIC_SDYF, _address)) return true;

        if (_hasRole(LP_ROLE, _address)) return true;

        return false;
    }

    /**
     * @notice Checks if address can interact with wrapped tokens
     * @dev DEPRECATED
     * @param _address the address
     * @return value returning if allowed to transact
     */
    function hasTokenPrivileges(address _address) public view returns (bool) {
        return isAllowed(_address);
    }

    /**
     * @notice Checks if address can interact with usyc
     * @param _address the address
     * @return value returning if allowed to transact
     */
    function canUSYC(address _address) public view returns (bool) {
        // Vaults / Systems are internal,
        // realistically they would not be sanctioned
        if (_hasRole(VAULT_ROLE, _address)) return true;
        if (_hasRole(SYSTEM_ROLE, _address)) return true;

        if (_sanctioned(_address)) return false;

        if (_hasRole(CLIENT_DOMESTIC_FEEDER, _address)) return true;
        if (_hasRole(CLIENT_INTERNATIONAL_FEEDER, _address)) return true;
        // checking international first because domestic is never used
        if (_hasRole(CLIENT_INTERNATIONAL_SDYF, _address)) return true;
        if (_hasRole(CLIENT_DOMESTIC_SDYF, _address)) return true;

        return false;
    }

    function grantRole(bytes32 _role, address _address) external {
        _checkOwner();
        _grantRole(_role, _address);
    }

    function grantRoleBatch(bytes32[] calldata _roles, address[] calldata _addresses) external {
        _checkOwner();

        unchecked {
            for (uint256 i; i < _roles.length; ++i) {
                _grantRole(_roles[i], _addresses[i]);
            }
        }
    }

    function revokeRole(bytes32 _role, address _address) external {
        _checkOwner();
        _revokeRole(_role, _address);
    }

    function revokeRoleBatch(bytes32[] calldata _roles, address[] calldata _addresses) external {
        _checkOwner();

        unchecked {
            for (uint256 i; i < _roles.length; ++i) {
                _revokeRole(_roles[i], _addresses[i]);
            }
        }
    }

    /**
     * @notice Checks if an address has a specific role and is not sanctioned
     * @param _role the the specific role
     * @param _address the address
     * @return value returning if allowed to transact
     */
    function hasRoleAndNotSanctioned(bytes32 _role, address _address) public view returns (bool) {
        return _hasRoleAndNotSanctioned(_role, _address);
    }

    /**
     * @notice Checks if an address has a specific role and is not sanctioned
     * @param _roles array of roles to check
     * @param _address the address
     * @return value returning if allowed to transact
     */
    function hasRoleAndNotSanctionedBatch(bytes32[] calldata _roles, address _address) public view returns (bool) {
        if (_sanctioned(_address)) return false;
        return _hasRoleBatch(_roles, _address);
    }

    /**
     * @notice Checks if an address has a specific role
     * @param _role the the specific role
     * @param _address the address
     * @return value returning if allowed to transact
     */
    function hasRole(bytes32 _role, address _address) public view returns (bool) {
        return _hasRole(_role, _address);
    }

    /**
     * @notice Checks if an address has a specific role
     * @param _roles array of role to check
     * @param _address the address
     * @return value returning if allowed to transact
     */
    function hasRoleBatch(bytes32[] calldata _roles, address _address) public view returns (bool) {
        return _hasRoleBatch(_roles, _address);
    }

    /**
     * @notice Pauses whitelist
     * @dev reverts on any check of permissions preventing any movement of funds
     *      between vault, auction, and option protocol
     */
    function pause() public {
        _checkOwner();

        _pause();
    }

    /**
     * @notice Unpauses whitelist
     */
    function unpause() public {
        _checkOwner();

        _unpause();
    }

    /*///////////////////////////////////////////////////////////////
                            Internal Functions
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Has at least one role
     */
    function _hasRoleBatch(bytes32[] calldata _roles, address _address) internal view returns (bool) {
        unchecked {
            for (uint256 i; i < _roles.length; ++i) {
                if (_hasRole(_roles[i], _address)) return true;
            }
        }
        return false;
    }

    function _hasRole(bytes32 _role, address _address) internal view returns (bool) {
        if (paused()) revert WL_Paused();

        if (_role == bytes32(0)) revert WL_BadRole();
        if (_address == address(0)) revert BadAddress();

        return permissions[_role][_address];
    }

    /**
     * @notice Grants role, ensures that client cannot be listed as multiple
     */
    function _grantRole(bytes32 _role, address _address) internal {
        if (
            _role == CLIENT_DOMESTIC_FEEDER || _role == CLIENT_INTERNATIONAL_FEEDER || _role == CLIENT_INTERNATIONAL_SDYF
                || _role == CLIENT_DOMESTIC_SDYF
        ) {
            if (_hasRole(CLIENT_DOMESTIC_FEEDER, _address)) revert WL_BadRole();
            if (_hasRole(CLIENT_INTERNATIONAL_FEEDER, _address)) revert WL_BadRole();
            if (_hasRole(CLIENT_INTERNATIONAL_SDYF, _address)) revert WL_BadRole();
            if (_hasRole(CLIENT_DOMESTIC_SDYF, _address)) revert WL_BadRole();
        } else {
            if (_hasRole(_role, _address)) revert WL_BadRole();
        }

        permissions[_role][_address] = true;

        emit RoleGranted(_role, _address, msg.sender);
    }

    function _revokeRole(bytes32 _role, address _address) internal {
        if (!_hasRole(_role, _address)) revert WL_BadRole();

        permissions[_role][_address] = false;

        emit RoleRevoked(_role, _address, msg.sender);
    }

    function _hasRoleAndNotSanctioned(bytes32 _role, address _address) internal view returns (bool) {
        return _hasRole(_role, _address) && !_sanctioned(_address);
    }

    /**
     * @notice Checks if an address is sanctioned
     * @param _address the address
     * @return value returning if allowed to transact
     */
    function _sanctioned(address _address) internal view returns (bool) {
        if (_address == address(0)) revert BadAddress();

        return sanctionsOracle != address(0) ? ISanctionsList(sanctionsOracle).isSanctioned(_address) : false;
    }

    function _checkOwner() internal view override {
        if (owner() != msg.sender) revert Unauthorized();
    }
}
