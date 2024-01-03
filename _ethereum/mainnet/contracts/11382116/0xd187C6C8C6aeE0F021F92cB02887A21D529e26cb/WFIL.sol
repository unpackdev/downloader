/// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.12;

/// Copyright (C) 2020 WFIL Labs, Inc.
/// @title WFIL
/// @author Nazzareno Massari @naszam
/// @notice Wrapped Filecoin
/// @dev All function calls are currently implemented without side effects through TDD approach
/// @dev OpenZeppelin Library is used for secure contract development

/*
██     ██ ███████ ██ ██ 
██     ██ ██      ██ ██ 
██  █  ██ █████   ██ ██ 
██ ███ ██ ██      ██ ██ 
 ███ ███  ██      ██ ███████ 
*/

import "./ERC20.sol";
import "./AccessControl.sol";
import "./Pausable.sol";

contract WFIL is ERC20, AccessControl, Pausable {

    /// @dev Roles
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /// @dev Events
    event Wrapped(address indexed to, uint256 amount);
    event Unwrapped(address indexed account, uint256 amount);
    event UnwrappedFrom(address indexed account, uint256 amount);

    constructor(address dao_)
        public
        ERC20("Wrapped Filecoin", "WFIL")
    {
        require(dao_ != address(0), "WFIL: dao set to zero address");
        _setupRole(DEFAULT_ADMIN_ROLE, dao_);

        _setupRole(PAUSER_ROLE, dao_);
    }

    /// @notice Fallback function
    /// @dev Added not payable to revert transactions not matching any other function which send value
    fallback() external {
        revert("WFIL: function not matching any other");
    }

    /// @notice Wrap WFIL
    /// @dev Mint WFIL
    /// @dev Access restricted only for Minters
    /// @param to Address of the recipient
    /// @param amount Amount of WFIL issued
    /// @return True if WFIL is successfully wrapped
    function wrap(address to, uint256 amount) external returns (bool) {
        require(hasRole(MINTER_ROLE, msg.sender), "WFIL: caller is not a minter");
        require(amount > 0, "WFIL: amount is zero");
        _mint(to, amount);
        emit Wrapped(to, amount);
        return true;
    }

    /// @notice Unwrap WFIL
    /// @dev Burn WFIL
    /// @param amount The amount of WFIL to unwrap
    /// @return True if WFIL is successfully unwrapped
    function unwrap(uint256 amount) external returns (bool) {
        require(amount > 0, "WFIL: amount is zero");
        _burn(msg.sender, amount);
        emit Unwrapped(msg.sender, amount);
        return true;
    }

    function unwrapFrom(address account, uint256 amount) external returns (bool) {
        require(amount > 0, "WFIL: amount is zero");
        uint256 decreasedAllowance = allowance(account, msg.sender).sub(amount, "WFIL: burn amount exceeds allowance");

        _approve(account, msg.sender, decreasedAllowance);
        _burn(account, amount);
        emit UnwrappedFrom(account, amount);
        return true;
    }

    /// @notice Add a new Minter
    /// @dev Access restricted only for Default Admin
    /// @param account Address of the new Minter
    function addMinter(address account) external returns (bool) {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "WFIL: caller is not the default admin");
        require(account != address(0), "WFIL: account is the zero address");
        grantRole(MINTER_ROLE, account);
        return true;
    }

    /// @notice Remove a Minter
    /// @dev Access restricted only for Default Admin
    /// @param account Address of the Minter
    function removeMinter(address account) external returns (bool) {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "WFIL: caller is not the default admin");
        revokeRole(MINTER_ROLE, account);
        return true;
    }

    /// @notice Pause all the functions
    /// @dev the caller must have the 'PAUSER_ROLE'
    function pause() external {
        require(hasRole(PAUSER_ROLE, msg.sender), "WFIL: must have pauser role to pause");
        _pause();
    }

    /// @notice Unpause all the functions
    /// @dev the caller must have the 'PAUSER_ROLE'
    function unpause() external {
        require(hasRole(PAUSER_ROLE, msg.sender), "WFIL: must have pauser role to unpause");
        _unpause();
    }

    /// @notice Hook to pause _mint(), _transfer() and _burn()
    /// @dev Override ERC20 Hook
    /// @dev Revert on transfers to token contract
    /// @param from Sender address
    /// @param to Recipient address
    /// @param amount Token amount
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override(ERC20) {
        require(to != address(this), "WFIL: transfer to the token contract");
        super._beforeTokenTransfer(from, to, amount);
        require(!paused(), "WFIL: token transfer while paused");
    }
}
