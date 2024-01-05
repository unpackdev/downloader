// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "./ContextUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./RolesLib.sol";

contract MinterRoleUpgradeable is ContextUpgradeable, OwnableUpgradeable {
    using RolesLib for RolesLib.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    RolesLib.Role private _minters;

    function __MinterRole_init_unchained() internal {
	    // no-op
    }
    function __MinterRole_init() internal initializer {
      __MinterRole_init_unchained();
    }

    modifier onlyMinter() {
        require(isMinter(_msgSender()), "MinterRole: caller does not have the Minter role");
        _;
    }

    function isMinter(address account) public virtual view returns (bool) {
        return account == owner();
    }

    function addMinter(address /* account */) public view virtual onlyMinter {
      revert("unsupported");
    }

    function renounceMinter() public pure {
      revert("unsupported");
    }
}
