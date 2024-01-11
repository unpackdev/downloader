// SPDX-License-Identifier: MIT
// Copyright (c) 2022 unReal Accelerator, LLC
// (https://github.com/unreal-accelerator/contracts)
pragma solidity ^0.8.9;

/**
 * @title AccessControlMinterRole
 * @dev This contract provides a common way to control access for minting contracts
 * The deployer wallet is set saved as the initial admin upon deployment.
 * Admin role is inherited from AccessControlEnumerable
 * Minter role is added here for convenience
 * grateRole() only allows these two roles
 * NOTE:
 */

import "./AccessControlEnumerable.sol";
import "./ERC165Checker.sol";

import "./ICreatorMinterERC721.sol";
import "./IMinterERC1155.sol";

contract AccessControlMinterRole is AccessControlEnumerable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER");

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /**
    @dev Returns the address of the current owner (index 0).
     */
    function owner() external view returns (address) {
        return getRoleMember(DEFAULT_ADMIN_ROLE, 0);
    }

    /**
    @dev Add admin account 
     */
    function grantAdminRole(address account) external {
        grantRole(DEFAULT_ADMIN_ROLE, account);
    }

    /**
    @dev Remove admin account 
     */
    function removeAdminRole(address account) external {
        require(account != _msgSender(), "Cannot remove self");
        revokeRole(DEFAULT_ADMIN_ROLE, account);
    }

    /**
     * @dev Function access control handled by AccessControl contract
     * @notice Account must support the minter interface. See {ICreatorMinterERC721}
     */
    function addMinterContract(address account) external {
        require(
            ERC165Checker.supportsInterface(
                account,
                type(ICreatorMinterERC721).interfaceId
            ) ||
                ERC165Checker.supportsInterface(
                    account,
                    type(IMinterERC1155).interfaceId
                ),
            "Invalid minter contract"
        );
        grantRole(MINTER_ROLE, account);
    }

    /**
    @dev Remove minter account
     */
    function removeMinterContract(address account) external {
        revokeRole(MINTER_ROLE, account);
    }

    /**
    @dev Grant an account a role. This contract supports the Admin and Minter roles
     */
    function _grantRole(bytes32 role, address account)
        internal
        virtual
        override
    {
        require(account != address(0), "Cannot grant role to null");
        require(
            role == MINTER_ROLE || role == DEFAULT_ADMIN_ROLE,
            "Invalid role"
        );
        super._grantRole(role, account);
    }

    /**
    @dev Modifier to check for Admin role
     */
    modifier onlyAuthorized() {
        validateAuthorized();
        _;
    }

    function validateAuthorized() private view {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Not authorized");
    }

    /**
    @dev Modifier to check for Minter role
     */
    modifier onlyMinter() {
        validateMinter();
        _;
    }

    function validateMinter() private view {
        require(hasRole(MINTER_ROLE, _msgSender()), "Must have minter role");
    }

    /**
    @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerable)
        returns (bool)
    {
        return AccessControlEnumerable.supportsInterface(interfaceId);
    }
}
