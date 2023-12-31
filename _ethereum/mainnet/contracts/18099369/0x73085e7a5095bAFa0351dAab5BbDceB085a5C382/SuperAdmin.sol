// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./Initializable.sol";

/// @title A super manager
/// @notice Supports the creation on a super admin role that can do specific actions
/// @dev There can only be one super admin account at a time
contract SuperAdmin is Initializable {
    /// @notice Address of the current super admin
    address public superAdmin;

    /// @notice Address of a potential super admin
    address public potentialSuperAdmin;

    /// @notice Logs the information about nomination of a potential super admin
    event SuperAdminNominated(address _potentialSuperAdmin);

    /// @notice Logs the information when the super admin role is transferred
    event SuperAdminChanged(address oldAdmin, address newAdmin);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice Initializes the contract with the deployer as the initial super admin
    function initialize() external initializer {
        superAdmin = msg.sender;
    }

    /// @dev Throws an error if the caller is not the super admin
    /// @param caller The address of the caller
    modifier onlySuperAdmin(address caller) {
        require(caller == superAdmin, "NotSuperAdmin");
        _;
    }

    /// @notice Transfers the super admin role to a potential super admin address using pull-over-push pattern
    /// @param _potentialSuperAdmin An address of a potential super admin
    function transferSuperAdmin(address _potentialSuperAdmin) external onlySuperAdmin(msg.sender) {
        require(_potentialSuperAdmin != address(0), "ZeroSuperAdmin");

        potentialSuperAdmin = _potentialSuperAdmin;

        emit SuperAdminNominated(_potentialSuperAdmin);
    }

    /// @notice Accepts the super admin role by a potential super admin
    function acceptSuperAdmin() external {
        address _superAdmin = superAdmin;
        address _potentialSuperAdmin = potentialSuperAdmin;

        require(msg.sender == _potentialSuperAdmin, "NotPotentialSuperAdmin");

        potentialSuperAdmin = address(0);
        superAdmin = _potentialSuperAdmin;

        emit SuperAdminChanged(_superAdmin, _potentialSuperAdmin);
    }

    /// @notice Checks if the caller is a valid super admin
    /// @param caller The address of the caller
    function isValidSuperAdmin(address caller) public view onlySuperAdmin(caller) {}

    uint256[60] private __gap;
}
