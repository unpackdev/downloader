// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "./Jaguars.sol";


contract Jaguars2 is Jaguars, OwnableUpgradeable
{
    function initialize2(address admin)
    public reinitializer(2)
    {
        _transferOwnership(admin);
    }

    function hasRole(bytes32 role, address account)
        public
        view
        override
        returns (bool)
    {
        return role == DEFAULT_ADMIN_ROLE && owner() == account || super.hasRole(role, account);
    }
}
