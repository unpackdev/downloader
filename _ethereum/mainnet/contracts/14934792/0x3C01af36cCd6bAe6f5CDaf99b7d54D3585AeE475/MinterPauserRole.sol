// SPDX-License-Identifier: MIT
// Cipher Mountain Contracts (last updated v0.0.1) (/ERC721Goats.sol)

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./AccessControlEnumerable.sol";

abstract contract MinterPauserRole is Ownable, AccessControlEnumerable {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    modifier onlyAdmin() {
        _checkAdmin(_msgSender());
        _;
    }
    
    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE` and `PAUSER_ROLE` to the
     * account that deploys the contract.
     */
    function _setupOwnerRoles(address account) internal virtual {
        _setupRole(DEFAULT_ADMIN_ROLE, account);
        _setupRole(MINTER_ROLE, account);
        _setupRole(PAUSER_ROLE, account);

        _setRoleAdmin(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(MINTER_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(PAUSER_ROLE, DEFAULT_ADMIN_ROLE);
    }

    function _checkAdmin(address account) internal virtual {
    	_checkRole(DEFAULT_ADMIN_ROLE, account);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Adds admin transfer functions to ownership transfer
     */
    function _transferOwnership(address newOwner) internal virtual override {
        _grantRole(DEFAULT_ADMIN_ROLE, newOwner);
        _grantRole(MINTER_ROLE, newOwner);
        _grantRole(PAUSER_ROLE, newOwner);

        _revokeRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _revokeRole(MINTER_ROLE, _msgSender());
        _revokeRole(PAUSER_ROLE, _msgSender());

        super._transferOwnership(newOwner);
    }
}
