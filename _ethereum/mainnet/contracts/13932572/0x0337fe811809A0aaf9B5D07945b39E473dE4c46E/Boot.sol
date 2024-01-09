// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "ERC20.sol";
import "AccessControl.sol";
import "draft-ERC20Permit.sol";
import "ERC20Votes.sol";

contract Boot is ERC20, AccessControl, ERC20Permit, ERC20Votes {
    // DEFAULT_ADMIN_ROLE may grant/revoke DEFAULT_ADMIN_ROLE and MINTER_ADMIN_ROLE.

    // MINTER_ADMIN_ROLE may grant/revoke MINTER_ROLE.
    bytes32 public constant MINTER_ADMIN_ROLE = keccak256("MINTER_ROLE");

    // MINTER_ROLE may mint.
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // The upper limit on the totalSupply() that may eventually be minted.
    uint256 public constant cap = 100000000 * 10**18;

    // Deployment
    //
    // After deployment both a DAO multiSig account and the deployer account
    // will have MINTER_ADMIN_ROLE but only the multiSig will have DEFAULT_ADMIN_ROLE.
    //
    // Eventually either the multiSig will invoke revokeRole(MINTER_ADMIN_ROLE, deployer)
    // or the deployer will invoke relinquishMinterAdminRole() to remove the deployer's
    // MINTER_ADMIN_ROLE.
    //
    // No minter is assigned by default.  The deployer, with its MINTER_ADMIN_ROLE, will
    // grant MINTER_ROLE to the first minters e.g. the BOOT Auction contract, VestLock, etc.
    // before relinquishing the MINTER_ADMIN_ROLE.  After relinquishing, the multiSig may
    // grant/revoke as needed.

    constructor(address daoMultiSig)
        ERC20("Boot Finance", "BOOT")
        ERC20Permit("Boot Finance")
    { 
        _setRoleAdmin(MINTER_ROLE, MINTER_ADMIN_ROLE);

        _grantRole(DEFAULT_ADMIN_ROLE, daoMultiSig);
        _grantRole(MINTER_ADMIN_ROLE, daoMultiSig);
        _grantRole(MINTER_ADMIN_ROLE, msg.sender);
    }

    function relinquishMinterAdminRole()
        public
        onlyRole(MINTER_ADMIN_ROLE)
    {
        _revokeRole(MINTER_ADMIN_ROLE, msg.sender);
    }

    function mint(address to, uint256 amount)
        public
        onlyRole(MINTER_ROLE)
    {
        require(totalSupply() + amount <= cap, "exceeds supply cap");
        _mint(to, amount);
    }

    // multiple inheritance overhead

    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._burn(account, amount);
    }
}