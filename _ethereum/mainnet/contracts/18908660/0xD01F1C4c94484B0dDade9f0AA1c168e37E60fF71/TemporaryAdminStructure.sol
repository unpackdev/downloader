// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import "./Initializable.sol";
import "./ITemporaryAdminStructure.sol";

/**
 * @title Dollet TemporaryAdminStructure
 * @author Dollet Team
 * @notice An admin manager used for testing and deployments.
 * @notice IMPORTANT: this contract will be replaced with the real one once the deployment and setup is complete.
 */
contract TemporaryAdminStructure is Initializable, ITemporaryAdminStructure {
    address public superAdmin;
    address public potentialSuperAdmin;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Throws an error if the caller is not the super admin.
     * @param _caller The address of the caller.
     */
    modifier onlySuperAdmin(address _caller) {
        require(_caller == superAdmin, "NotSuperAdmin");
        _;
    }

    /**
     * @notice Initializes the contract with the deployer as the initial super admin.
     */
    function initialize() external initializer {
        superAdmin = msg.sender;
    }

    /// @inheritdoc ITemporaryAdminStructure
    function transferSuperAdmin(address _potentialSuperAdmin) external onlySuperAdmin(msg.sender) {
        potentialSuperAdmin = _potentialSuperAdmin;
    }

    /// @inheritdoc ITemporaryAdminStructure
    function acceptSuperAdmin() external {
        address _potentialSuperAdmin = potentialSuperAdmin;

        require(msg.sender == _potentialSuperAdmin, "NotPotentialSuperAdmin");

        potentialSuperAdmin = address(0);
        superAdmin = _potentialSuperAdmin;
    }

    /// @inheritdoc ITemporaryAdminStructure
    function isValidAdmin(address _caller) external view onlySuperAdmin(_caller) { }

    /// @inheritdoc ITemporaryAdminStructure
    function isValidSuperAdmin(address _caller) external view onlySuperAdmin(_caller) { }

    /// @inheritdoc ITemporaryAdminStructure
    function getAllAdmins() external view returns (address[] memory _adminsList) {
        _adminsList = new address[](1);
        _adminsList[0] = superAdmin;
    }
}
