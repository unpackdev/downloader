// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./ReentrancyGuard.sol";
import "./AccessControl.sol";

contract Hope is ERC20, AccessControl, ReentrancyGuard {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor() ERC20("Hope", "HOPE") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function burnHope(uint256 amount) external nonReentrant {
        _burn(msg.sender, amount);
    }

    function mintHopeTokenForCopacabanaCasino(address receiver, uint256 amount) external onlyRole(MINTER_ROLE) {
        _mint(receiver, amount);
    }
}
