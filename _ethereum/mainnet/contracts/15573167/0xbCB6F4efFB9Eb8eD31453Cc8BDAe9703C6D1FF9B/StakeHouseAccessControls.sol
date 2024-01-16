// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

import "./AccessControl.sol";

/// @title Ledger of addresses and roles they hold within the StakeHouse universe
contract StakeHouseAccessControls is AccessControl {

    /// @dev Role name definitions
    bytes32 public immutable PROXY_ADMIN_ROLE = keccak256("PROXY_ADMIN_ROLE");
    bytes32 public immutable CORE_MODULE_ADMIN_ROLE = keccak256("CORE_MODULE_ADMIN_ROLE");
    bytes32 public immutable CORE_MODULE_MANAGER_ROLE = keccak256("CORE_MODULE_MANAGER_ROLE");
    bytes32 public immutable CORE_MODULE_ROLE = keccak256("CORE_MODULE_ROLE");
    bytes32 public immutable COMMON_INTEREST_MANAGER_ROLE = keccak256("COMMON_INTEREST_MANAGER_ROLE");

    /// @notice If a core module is locked - it cannot be removed from the system
    mapping(address => bool) public isCoreModuleLocked;

    event CommonInterestManagerRoleGranted(address indexed beneficiary);
    event CommonInterestManagerRoleRemoved(address indexed beneficiary);
    event AdminRoleGranted(address indexed beneficiary);
    event AdminRoleRemoved(address indexed beneficiary);
    event ProxyAdminRoleGranted(address indexed beneficiary);
    event ProxyAdminRoleRemoved(address indexed beneficiary);
    event CoreModuleRoleGranted(address indexed beneficiary);
    event CoreModuleRoleRemoved(address indexed beneficiary);
    event CoreModuleLocked(address indexed coreModule);
    event CoreModuleManagerRoleGranted(address indexed beneficiary);
    event CoreModuleManagerRoleRemoved(address indexed beneficiary);
    event CoreModuleAdminRoleGranted(address indexed beneficiary);
    event CoreModuleAdminRoleRemoved(address indexed beneficiary);

    /// @dev Core module hierarchy set up and _superAdmin address is given 3 roles:
    // DEFAULT_ADMIN_ROLE
    // CORE_MODULE_ADMIN_ROLE
    // CORE_MODULE_MANAGER_ROLE
    /// @dev no other account is allowed to have more than 1 role to try to encourage role distribution
    /// @param _superAdmin Account that will receive the aforementioned roles
    constructor(address _superAdmin) {
        require(_superAdmin != address(0), "Admin cannot be zero");
        _setRoleAdmin(CORE_MODULE_ADMIN_ROLE, CORE_MODULE_ADMIN_ROLE);
        _setRoleAdmin(CORE_MODULE_MANAGER_ROLE, CORE_MODULE_ADMIN_ROLE);
        _setRoleAdmin(CORE_MODULE_ROLE, CORE_MODULE_MANAGER_ROLE);

        _setupRole(DEFAULT_ADMIN_ROLE, _superAdmin);
        _setupRole(CORE_MODULE_ADMIN_ROLE, _superAdmin);
        _setupRole(CORE_MODULE_MANAGER_ROLE, _superAdmin);
        _setupRole(COMMON_INTEREST_MANAGER_ROLE, _superAdmin);
    }

    /// @notice Checks if an address has the DEFAULT_ADMIN_ROLE
    function isAdmin(address _address) public view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, _address);
    }

    /// @notice Checks if an address has the COMMON_INTEREST_MANAGER_ROLE
    function isCommonInterestManager(address _address) public view returns (bool) {
        return hasRole(COMMON_INTEREST_MANAGER_ROLE, _address);
    }

    /// @notice Checks if an address has the PROXY_ADMIN_ROLE
    function isProxyAdmin(address _address) public view returns (bool) {
        return hasRole(PROXY_ADMIN_ROLE, _address);
    }

    /// @notice Checks if an address has the CORE_MODULE_ROLE
    function isCoreModule(address _address) public view returns (bool) {
        return hasRole(CORE_MODULE_ROLE, _address);
    }

    /// @notice Checks if an address has the CORE_MODULE_MANAGER_ROLE
    function isCoreModuleManager(address _address) public view returns (bool) {
        return hasRole(CORE_MODULE_MANAGER_ROLE, _address);
    }

    /// @notice Checks if an address has the CORE_MODULE_ADMIN_ROLE
    function isCoreModuleAdmin(address _address) public view returns (bool) {
        return hasRole(CORE_MODULE_ADMIN_ROLE, _address);
    }

    /// @notice Allows an account with DEFAULT_ADMIN_ROLE to add another DEFAULT_ADMIN_ROLE to another account
    function addAdmin(address _address) external {
        require(isAdmin(msg.sender), "Only admin");
        require(!isProxyAdmin(_address), "Admin cannot also have proxy admin");
        require(!isCoreModule(_address), "Admin cannot also be a core module");
        require(!isCoreModuleManager(_address), "Admin cannot also be a core module manager");
        require(!isCoreModuleAdmin(_address), "Admin cannot also be a core module admin");
        require(!isCommonInterestManager(_address), "Cannot also be common interest manager");
        _grantRole(DEFAULT_ADMIN_ROLE, _address);
        emit AdminRoleGranted(_address);
    }

    /// @notice Allows an account with DEFAULT_ADMIN_ROLE to remove the DEFAULT_ADMIN_ROLE
    function removeAdmin(address _address) external {
        require(isAdmin(msg.sender), "Only admin");
        _revokeRole(DEFAULT_ADMIN_ROLE, _address);
        emit AdminRoleRemoved(_address);
    }

    /// @notice Allows an account with DEFAULT_ADMIN_ROLE to grant the COMMON_INTEREST_MANAGER_ROLE
    function addCommonInterestManager(address _address) external {
        require(isAdmin(msg.sender), "Only admin");
        require(!isAdmin(_address), "Address cannot also be admin");
        require(!isProxyAdmin(_address), "Address cannot also have proxy admin");
        require(!isCoreModule(_address), "Address cannot also be a core module");
        require(!isCoreModuleManager(_address), "Address cannot also be a core module manager");
        require(!isCoreModuleAdmin(_address), "Address cannot also be a core module admin");
        _grantRole(COMMON_INTEREST_MANAGER_ROLE, _address);
        emit CommonInterestManagerRoleGranted(_address);
    }

    /// @notice Allows an account with DEFAULT_ADMIN_ROLE to remove the COMMON_INTEREST_MANAGER_ROLE
    function removeCommonInterestManager(address _address) external {
        require(isAdmin(msg.sender), "Only admin");
        _revokeRole(COMMON_INTEREST_MANAGER_ROLE, _address);
        emit CommonInterestManagerRoleRemoved(_address);
    }

    /// @notice Allows an account with DEFAULT_ADMIN_ROLE to add PROXY_ADMIN_ROLE to another account
    function addProxyAdmin(address _address) external {
        require(isAdmin(msg.sender), "Only admin");
        require(!isAdmin(_address), "Admin cannot also have proxy admin");
        require(!isCoreModule(_address), "Proxy admin cannot also be a core module");
        require(!isCoreModuleManager(_address), "Proxy admin cannot also be a core module manager");
        require(!isCoreModuleAdmin(_address), "Admin cannot also be a core module admin");
        require(!isCommonInterestManager(_address), "Cannot also be common interest manager");
        _grantRole(PROXY_ADMIN_ROLE, _address);
        emit ProxyAdminRoleGranted(_address);
    }

    /// @notice Allows an account with DEFAULT_ADMIN_ROLE to remove PROXY_ADMIN_ROLE from another account
    function removeProxyAdmin(address _address) external {
        require(isAdmin(msg.sender), "Only admin");
        _revokeRole(PROXY_ADMIN_ROLE, _address);
        emit ProxyAdminRoleRemoved(_address);
    }

    /// @notice Allows an account with CORE_MODULE_MANAGER_ROLE or CORE_MODULE_ADMIN_ROLE to add CORE_MODULE_ROLE to another account
    function addCoreModule(address _address) external {
        require(isCoreModuleAdmin(msg.sender) || isCoreModuleManager(msg.sender), "Only admin or core module manager");
        require(!isProxyAdmin(_address), "Proxy admin cannot also be core module");
        require(!isAdmin(_address), "Admin cannot also be a core module");
        require(!isCoreModuleManager(_address), "Core module manager cannot also be a core module");
        require(!isCoreModuleAdmin(_address), "Admin cannot also be a core module");
        require(!isCommonInterestManager(_address), "Cannot also be common interest manager");
        _grantRole(CORE_MODULE_ROLE, _address);
        emit CoreModuleRoleGranted(_address);
    }

    /// @notice Allows an account with CORE_MODULE_MANAGER_ROLE to remove CORE_MODULE_ROLE from an account
    function removeCoreModule(address _address) external {
        require(isCoreModuleManager(msg.sender) || isCoreModuleAdmin(msg.sender), "Only core module manager");
        require(!isCoreModuleLocked[_address], "Core module locked");
        _revokeRole(CORE_MODULE_ROLE, _address);
        emit CoreModuleRoleRemoved(_address);
    }

    /// @notice Allows CORE_MODULE_ADMIN_ROLE or CORE_MODULE_MANAGER_ROLE to lock a CORE_MODULE preventing it from being removed
    function lockCoreModule(address _coreModule) external {
        require(isCoreModuleAdmin(msg.sender) || isCoreModuleManager(msg.sender), "Only admin or manager");
        isCoreModuleLocked[_coreModule] = true;
        emit CoreModuleLocked(_coreModule);
    }

    /// @notice Allows CORE_MODULE_ADMIN_ROLE to grant CORE_MODULE_MANAGER_ROLE to any address
    function addCoreModuleManager(address _address) external {
        require(isCoreModuleAdmin(msg.sender), "Only admin");
        require(!isProxyAdmin(_address), "Proxy admin cannot also be core module");
        require(!isAdmin(_address), "Admin cannot also be a core module");
        require(!isCoreModule(_address), "Core module manager cannot also be a core module");
        require(!isCoreModuleAdmin(_address), "Manager cannot also be a core module admin");
        require(!isCommonInterestManager(_address), "Cannot also be common interest manager");
        _grantRole(CORE_MODULE_MANAGER_ROLE, _address);
        emit CoreModuleManagerRoleGranted(_address);
    }

    /// @notice Allows CORE_MODULE_ADMIN_ROLE to remove CORE_MODULE_MANAGER_ROLE from any address
    function removeCoreModuleManager(address _address) external {
        require(isCoreModuleAdmin(msg.sender), "Only admin");
        _revokeRole(CORE_MODULE_MANAGER_ROLE, _address);
        emit CoreModuleManagerRoleRemoved(_address);
    }

    /// @notice Allows CORE_MODULE_ADMIN_ROLE to add CORE_MODULE_ADMIN_ROLE to any address
    function addCoreModuleAdmin(address _address) external {
        require(isCoreModuleAdmin(msg.sender), "Only admin");
        require(!isProxyAdmin(_address), "Proxy admin cannot also be core module admin");
        require(!isAdmin(_address), "Admin cannot also be a core module admin");
        require(!isCoreModule(_address), "Core module admin cannot also be a core module");
        require(!isCoreModuleManager(_address), "Manager cannot also be a core module admin");
        require(!isCommonInterestManager(_address), "Cannot also be common interest manager");
        _grantRole(CORE_MODULE_ADMIN_ROLE, _address);
        emit CoreModuleAdminRoleGranted(_address);
    }

    /// @notice Allows CORE_MODULE_ADMIN_ROLE to remove CORE_MODULE_ADMIN_ROLE from any address
    function removeCoreModuleAdmin(address _address) external {
        require(isCoreModuleAdmin(msg.sender), "Only admin");
        _revokeRole(CORE_MODULE_ADMIN_ROLE, _address);
        emit CoreModuleAdminRoleRemoved(_address);
    }

    /// @notice Overriden to remove its behaviour. Calling this will achieve nothing
    function grantRole(bytes32, address) public pure override {
        revert("Blocked");
    }

    /// @notice Overriden to remove its behaviour. Calling this will achieve nothing
    function revokeRole(bytes32, address) public pure override {
        revert("Blocked");
    }
}
