// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./AccessControl.sol";

/** @title Paladin Token contract  */
/// @author Paladin
contract LaunchPAL is ERC20, AccessControl {
    /** @notice The identifier for admin role */
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");
    /** @notice The identifier for transfer-allwoed role */
    bytes32 public constant TRANSFER_ROLE = keccak256("TRANSFER");


    // Storage :

    /** @notice boolean allowing transfer for all users */
    bool public transfersAllowed = true;

    // Events :

    /** @notice Emitted when transfer toggle is switched */
    event TransfersAllowed(bool transfersAllowed);

    // Modifiers :

    /** @dev Allows only ADMIN role to call the function */
    modifier onlyAdmin() {
        require(
            hasRole(ADMIN_ROLE, msg.sender),
            "PaladinToken: caller not admin"
        );
        _;
    }

    /** @dev Allows only caller with the TRANSFER role to execute transfer */
    modifier onlyTransferer(address from) {
        require(
            transfersAllowed || hasRole(TRANSFER_ROLE, msg.sender),
            "PaladinToken: caller cannot transfer"
        );
        _;
    }

    constructor(
        uint256 initialSupply,
        address admin,
        address recipient
    ) ERC20("Launch Paladin Token", "lPAL") {
        _setupRole(TRANSFER_ROLE, admin);
        _setupRole(TRANSFER_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, admin);
        _setRoleAdmin(TRANSFER_ROLE, ADMIN_ROLE);
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);

        _mint(recipient, initialSupply);
    }

    /** @dev Hook called before any transfer */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override onlyTransferer(from) {}


    // Admin methods :

    /**
     * @notice Allow/Block transfer for all users
     * @dev Change transfersAllowed flag
     * @param _transfersAllowed bool : true to allow Transfer, false to block
     */
    function setTransfersAllowed(bool _transfersAllowed) external onlyAdmin {
        transfersAllowed = _transfersAllowed;
        emit TransfersAllowed(transfersAllowed);
    }
}
