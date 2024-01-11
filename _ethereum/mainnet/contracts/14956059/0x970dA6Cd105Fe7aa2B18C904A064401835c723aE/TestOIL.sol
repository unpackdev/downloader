// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "ERC20.sol";
import "ERC20Burnable.sol";
import "Pausable.sol";
import "AccessControl.sol";
import "draft-ERC20Permit.sol";


contract TestOIL is ERC20, ERC20Burnable, Pausable, AccessControl, ERC20Permit {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant PREDICATE_ROLE = keccak256("PREDICATE_ROLE");  // following https://docs.polygon.technology/docs/develop/ethereum-polygon/mintable-assets/

    constructor() ERC20("TestOIL", "TestOIL") ERC20Permit("TestOIL") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
        _setupRole(PREDICATE_ROLE, msg.sender);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyRole(PREDICATE_ROLE) {
        _mint(to, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}
