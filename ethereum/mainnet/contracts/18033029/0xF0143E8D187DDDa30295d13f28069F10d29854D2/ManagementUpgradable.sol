// SPDX-License-Identifier: MIT

pragma solidity >=0.8.16;

import "./PausableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./Initializable.sol";

contract ManagementUpgradeable is Initializable, PausableUpgradeable, AccessControlUpgradeable {
    bytes32 constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    error ManagementError(string errMsg);
    string constant CANT_SEND = "Failed to send Ether";
    string constant CANT_REMOVE_SENDER = "Can't remove sender";

    error InvalidInput(string errMsg);
    string constant INVALID_ADDRESS = "Invalid wallet address";

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function __Management_init()  internal onlyInitializing {
        __Pausable_init();
        __AccessControl_init();

        _grantRole(MANAGER_ROLE, msg.sender);
    }

    /** ----------------------------------
     * ! Admin functions
     * ----------------------------------- */

    /**
     * @notice Add a manager address (contract or wallet) to manage this contract
     * @dev This function can only to called from contracts or wallets with MANAGER_ROLE
     * @param newManager The new manager address to be granted
     */
    function addManager(address newManager) external onlyRole(MANAGER_ROLE) {
        if (newManager == address(0)) revert InvalidInput(INVALID_ADDRESS);
        _grantRole(MANAGER_ROLE, newManager);
    }

    /**
 * @notice Set manager address (contract or wallet) to manage this contract
     * @dev This function can only to called from contracts or wallets with MANAGER_ROLE
     * @param manager The manager address to be revoked, can not be the same as the caller
     */
    function removeManager(address manager) external onlyRole(MANAGER_ROLE) {
        if (manager == address(0)) revert InvalidInput(INVALID_ADDRESS);
        if (manager == msg.sender) revert ManagementError(CANT_REMOVE_SENDER);
        _revokeRole(MANAGER_ROLE, manager);
    }

    /** ----------------------------------
     * ! Pausing functions
     * ----------------------------------- */

    function pause() public onlyRole(MANAGER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(MANAGER_ROLE) {
        _unpause();
    }


}
