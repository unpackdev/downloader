// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.6;

import {Errors} from "Errors.sol";

/**
 * @title AdminPausableUpgradeSafe
 *
 * @dev Contract to be inherited from that adds simple administrator pausable functionality. This does not
 * implement any changes on its own as there is no constructor or initializer. Both _admin and _paused must
 * be initialized in the inheriting contract.
 * @dev Inspired by `@openzeppelin-upgradeable/contracts/security/PausableUpgradeable.sol`
 */
contract AdminPausableUpgradeSafe {
    address internal _admin;
    bool internal _paused;

    /**
     * @notice Emitted when the contract is paused.
     *
     * @param admin The current administrator address.
     */
    event Paused(address admin);

    /**
     * @notice Emitted when the contract is unpaused.
     *
     * @param admin The current administrator address.
     */
    event Unpaused(address admin);

    /**
     * @notice Emitted when the admin is set to a different address.
     *
     * @param to The address of the new administrator.
     */
    event AdminChanged(address to);

    /**
     * @dev Modifier to only allow functions to be called when not paused.
     */
    modifier whenNotPaused() {
        require(!_paused, Errors.PAUSED);
        _;
    }

    /**
     * @dev Modifier to only allow the admin as the caller.
     */
    modifier onlyAdmin() {
        require(msg.sender == _admin, Errors.NOT_ADMIN);
        _;
    }

    /**
     * @dev Admin function pauses the contract.
     */
    function pause() external onlyAdmin {
        _paused = true;
        emit Paused(_admin);
    }

    /**
     * @dev Admin function unpauses the contract.
     */
    function unpause() external onlyAdmin {
        _paused = false;
        emit Unpaused(_admin);
    }

    /**
     * @dev Admin function that changes the administrator.
     * @dev It is possible to set admin to address(0) (to disable administration), be careful!
     */
    function changeAdmin(address to) external onlyAdmin {
        _admin = to;
        emit AdminChanged(to);
    }

    /**
     * @dev View function that returns the current admin.
     */
    function getAdmin() external view returns (address) {
        return _admin;
    }

    uint256[3] private __gap;  // contract uses small number of slots (5 in total)
}