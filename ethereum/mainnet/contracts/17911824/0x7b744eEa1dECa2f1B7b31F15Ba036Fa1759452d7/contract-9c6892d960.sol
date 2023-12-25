// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Snapshot.sol";
import "./AccessControl.sol";
import "./draft-ERC20Permit.sol";

contract ElHippo is ERC20, ERC20Burnable, ERC20Snapshot, AccessControl, ERC20Permit {
    bytes32 public constant SNAPSHOT_ROLE = keccak256("SNAPSHOT_ROLE");

    constructor() ERC20("El Hippo", "HIPP") ERC20Permit("El Hippo") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(SNAPSHOT_ROLE, msg.sender);
        _mint(msg.sender, 777000000000000 * 10 ** decimals());
    }

    function snapshot() public onlyRole(SNAPSHOT_ROLE) {
        _snapshot();
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Snapshot)
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}
