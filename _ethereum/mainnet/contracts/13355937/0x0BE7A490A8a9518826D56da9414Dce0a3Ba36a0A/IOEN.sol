// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AccessControlEnumerable.sol";
import "./ERC20.sol";
import "./draft-ERC20Permit.sol";
import "./Pausable.sol";


contract IOEN is Pausable, AccessControlEnumerable, ERC20Permit {
    string constant NAME    = 'IOEN';
    string constant SYMBOL  = 'IOEN';
    uint8 constant DECIMALS  = 18;
    uint256 constant INITIAL_SUPPLY = 1_000_000_000 * 10**uint256(DECIMALS);

    bytes32 public constant WHITELISTED_MSG_SENDER_ROLE = keccak256("WHITELISTED_MSG_SENDER_ROLE");
    bytes32 public constant WHITELISTED_FROM_ROLE = keccak256("WHITELISTED_FROM_ROLE");

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "!admin");
        _;
    }

    constructor(address owner) ERC20(NAME, SYMBOL) ERC20Permit(NAME) {
        _setupRole(DEFAULT_ADMIN_ROLE, owner);              // DEFAULT_ADMIN_ROLE can grant other roles
        _setupRole(WHITELISTED_MSG_SENDER_ROLE, owner);     // Allows manual transfers
        _setupRole(WHITELISTED_FROM_ROLE, owner);           // Allows to interract with contracts
        _mint(owner, INITIAL_SUPPLY);
    }

    /**
     * @notice Triggers stopped state.
     * Requirements:
     * - The contract must not be paused.
     */
    function pause() external onlyAdmin {
        _pause();
    }

    /**
     * @notice Returns to normal state.
     * Requirements:
     * - The contract must be paused.
     */
    function unpause() external onlyAdmin {
        _unpause();
    }

    /**
     * @dev Called before any transfer, including mint/burn
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override(ERC20) {
        super._beforeTokenTransfer(from, to, amount);

        require(
            !paused(), // unpaused mode
            "transfers paused"
        );
    }

}
