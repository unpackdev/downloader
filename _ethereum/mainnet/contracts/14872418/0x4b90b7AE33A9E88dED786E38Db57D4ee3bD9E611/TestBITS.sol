// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "ERC20.sol";
import "Pausable.sol";
import "AccessControl.sol";
import "draft-ERC20Permit.sol";


contract TestBITS is ERC20, Pausable, AccessControl, ERC20Permit {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    constructor() ERC20("TestBITS", "TestBITS") ERC20Permit("TestBITS") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);

        _mint(msg.sender, 1e9 * 1e18);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}
