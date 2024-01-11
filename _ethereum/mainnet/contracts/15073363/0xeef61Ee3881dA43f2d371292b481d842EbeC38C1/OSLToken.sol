// ----------------------------------------------------------------------------
// Copyright (c) 2022 BC Technology (Hong Kong) Limited
// https://bc.group
// See LICENSE file for license details.
// ----------------------------------------------------------------------------

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./ERC20.sol";
import "./Pausable.sol";

import "./WhitelistCompliant.sol";
import "./SuspendCompliant.sol";
import "./AccessGuard.sol";

/// @title OSLToken
/// @notice Extended ERC20 permissioned contract with whitelist and suspend compliance verification.
contract OSLToken is
    ERC20,
    Pausable,
    AccessGuard,
    WhitelistCompliant,
    SuspendCompliant
{
    /*==================== Events ====================*/

    event OperatorTransfer(
        address indexed operator,
        address sender,
        address recipient,
        uint256 amount
    );

    event OperatorTransferBatch(
        address indexed operator,
        address[] senders,
        address[] recipients,
        uint256[] amounts
    );

    event OperatorBurn(
        address indexed operator,
        address account,
        uint256 amount
    );

    event OperatorBurnBatch(
        address indexed operator,
        address[] accounts,
        uint256[] amounts
    );

    event OperatorMint(
        address indexed operator,
        address account,
        uint256 amount
    );

    event OperatorMintBatch(
        address indexed operator,
        address[] accounts,
        uint256[] amounts
    );

    /*==================== Global variables ====================*/

    /// @dev Boolean set in the constructor to enable whitelist
    bool public immutable whitelistEnabled;

    /// @dev Boolean set in the constructor to enable `operatorTransferBatch`
    bool public immutable operatorTransferEnabled;

    /// @dev Boolean set in the constructor to enable `operatorBurnBatch`
    bool public immutable operatorBurnEnabled;

    /// @dev Variable to hold the number of decimals
    uint8 private immutable _decimals;

    /// @notice
    /// @dev
    /// @param enableWhitelist_ (bool) enable whitelist or not
    /// @param enableOperatorTransfer_ (bool) enable operator batch transfer
    /// @param enableOperatorBurns_ (bool) enable operator batch burn
    /// @param name_ (string) name of the ERC20 token
    /// @param symbol_ (string) symbol of the ERC20 token
    /// @param defaultAdmin_ (address) wallet address of the initial admin
    constructor(
        bool enableWhitelist_,
        bool enableOperatorTransfer_,
        bool enableOperatorBurns_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address defaultAdmin_
    ) ERC20(name_, symbol_) {
        whitelistEnabled = enableWhitelist_;
        operatorTransferEnabled = enableOperatorTransfer_;
        operatorBurnEnabled = enableOperatorBurns_;
        _decimals = decimals_;

        _setupRole(DEFAULT_ADMIN_ROLE, defaultAdmin_);
    }

    /// @notice Burn an amount from the owners balance. Can only be called if the owner of the wallet
    /// is whitelisted & not suspended
    /// @param amount (uint256) amount to be burned
    function burn(uint256 amount) external whenNotPaused {
        require(
            !isSuspended(_msgSender()),
            "OSLToken: Address must not be suspended"
        );
        require(
            _verifyWhitelist(_msgSender()),
            "OSLToken: Address must be whitelisted"
        );

        _burn(_msgSender(), amount);
    }

    /*==================== Operator Only Functions ====================*/

    /// @notice Pause the contract. Can only be called by operators.
    /// @dev
    function pause() external onlyRole(OPERATOR_ROLE) {
        _pause();
    }

    /// @notice Unpause the contract. Can only be called by operators.
    /// @dev
    function proceed() external onlyRole(OPERATOR_ROLE) {
        _unpause();
    }

    /// @notice Only available if `operatorTransferEnabled` is set true in the constructor. Transfer from an address to
    /// another address a specific amount. It can only be called by operators. This function is similar to the `operatorTransferBatch`
    /// but works for single accounts
    /// @dev Each index of each array is mapped directly so senders[1] will transfer to recipients[1], amount[1] and so on
    /// @param sender (address) Account transfer sender
    /// @param recipient (address) Account transfer recipient
    /// @param amount (uint256) Amount to be transferred
    function operatorTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) external onlyRole(OPERATOR_ROLE) whenNotPaused {
        require(
            operatorTransferEnabled,
            "OSLToken: Operator transfer not enabled"
        );
        require(
            !isSuspended(sender) && !isSuspended(recipient),
            "OSLToken: Addresses must not be suspended"
        );

        _transfer(sender, recipient, amount);

        emit OperatorTransfer(_msgSender(), sender, recipient, amount);
    }

    /// @notice Only available if `operatorTransferEnabled` is set true in the constructor. Transfer from a list of addresses to
    /// another list of addresses specific amounts. It can only be called by operators. This function will only check if the accounts
    /// are not suspended.
    /// @dev Each index of each array is mapped directly so senders[1] will transfer to recipients[1], amount[1] and so on
    /// @param senders (address[]) List of source address
    /// @param recipients (address[]) List of target addresses
    /// @param amounts (uint256[]) List of amounts to be transferred
    function operatorTransferBatch(
        address[] calldata senders,
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external onlyRole(OPERATOR_ROLE) whenNotPaused {
        require(
            operatorTransferEnabled,
            "OSLToken: Operator transfer not enabled"
        );
        require(
            senders.length == recipients.length &&
                recipients.length == amounts.length,
            "OSLToken: Mismatching argument sizes"
        );

        for (uint256 index = 0; index < senders.length; index++) {
            require(
                !isSuspended(senders[index]) && !isSuspended(recipients[index]),
                "OSLToken: Addresses must not be suspended"
            );
            _transfer(senders[index], recipients[index], amounts[index]);
        }

        emit OperatorTransferBatch(_msgSender(), senders, recipients, amounts);
    }

    /// @notice Only available if `operatorBurnEnabled` is set true in the constructor. Burn an amount from an account.
    /// Can only be called by operators. It can burn tokens even if the account is suspended or not whitelisted.
    /// @param account (address) Account to burn from
    /// @param amount (uint256) Amount to be burned
    function operatorBurn(address account, uint256 amount)
        external
        onlyRole(OPERATOR_ROLE)
        whenNotPaused
    {
        require(operatorBurnEnabled, "OSLToken: Operator burn not enabled");

        _burn(account, amount);

        emit OperatorBurn(_msgSender(), account, amount);
    }

    /// @notice Only available if `operatorBurnEnabled` is set true in the constructor. Burn from a list of addresses a list of amounts.
    /// Can only be called by operators.
    /// @dev Each index of each array is mapped directly so accounts[1] will get a burn with amount[1] tokens and so on
    /// @param accounts (address[]) List of accounts to burn from
    /// @param amounts (uint256[]) List of amounts to be burned
    function operatorBurnBatch(
        address[] calldata accounts,
        uint256[] calldata amounts
    ) external onlyRole(OPERATOR_ROLE) whenNotPaused {
        require(operatorBurnEnabled, "OSLToken: Operator burn not enabled");
        require(
            accounts.length == amounts.length,
            "OSLToken: Mismatching argument sizes"
        );

        for (uint256 index = 0; index < accounts.length; index++) {
            _burn(accounts[index], amounts[index]);
        }

        emit OperatorBurnBatch(_msgSender(), accounts, amounts);
    }

    /// @notice Mint an amount to an account. Can only be called by operators.
    /// @dev Similar to `operatorMintBatch` but for single accounts
    /// @param account (address) Account to mint to
    /// @param amount (uint256) Amount to be minted
    function operatorMint(address account, uint256 amount)
        external
        onlyRole(OPERATOR_ROLE)
        whenNotPaused
    {
        require(
            !isSuspended(account),
            "OSLToken: Address must not be suspended"
        );

        _mint(account, amount);

        emit OperatorMint(_msgSender(), account, amount);
    }

    /// @notice Mint to list of addresses a list of amounts. Can only be called by operators.
    /// @dev Each index of each array is mapped directly so accounts[1] will get a minted amount[1] tokens and so on
    /// @param accounts (address[]) List of accounts to mint to
    /// @param amounts (uint256[]) List of amounts to be minted
    function operatorMintBatch(
        address[] calldata accounts,
        uint256[] calldata amounts
    ) external onlyRole(OPERATOR_ROLE) whenNotPaused {
        require(
            accounts.length == amounts.length,
            "OSLToken: Mismatching argument sizes"
        );

        for (uint256 index = 0; index < accounts.length; index++) {
            require(
                !isSuspended(accounts[index]),
                "OSLToken: Address must not be suspended"
            );
            _mint(accounts[index], amounts[index]);
        }

        emit OperatorMintBatch(_msgSender(), accounts, amounts);
    }

    /*==================== Internal Functions ====================*/

    /// @notice If whitelist enabled verify if the account is whitelisted
    /// @dev Will return true if `whitelistEnabled` is `false` or if `whitelistEnabled` is `true` and the account
    /// argument is whitelisted
    /// @param account (address) Account to verify if whitelisted
    function _verifyWhitelist(address account) internal view returns (bool) {
        return !whitelistEnabled || isWhitelisted(account);
    }

    /*==================== Override ERC20 Functions ====================*/

    /// @notice Override default `decimals` function from ERC20 to return from the value from the global state
    /// @return (uint256) Decimal value of ERC20
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    /// @notice Override default `transferFrom` function from ERC20 to check whitelist & suspend status also block while paused
    /// @dev Overwrite default `transferFrom` functionality while using the super inheritance call after verifying pause and compliance status
    /// @param sender (address) Sender of tokens
    /// @param recipient (address) Recipient of tokens
    /// @param amount (uint256) Amount of tokens to be transferred
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override whenNotPaused returns (bool) {
        require(
            !isSuspended(sender) && !isSuspended(recipient),
            "OSLToken: Addresses must not be suspended"
        );
        require(
            _verifyWhitelist(sender) && _verifyWhitelist(recipient),
            "OSLToken: Addresses must be whitelisted"
        );

        return super.transferFrom(sender, recipient, amount);
    }

    /// @notice Override default `transfer` function from ERC20 to check whitelist & suspend status also block while paused
    /// @dev Overwrite default `transfer` functionality while using the super inheritance call after verifying pause and compliance status
    /// @param recipient (address) Recipient of tokens
    /// @param amount (uint256) Amount of tokens to be transferred
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        whenNotPaused
        returns (bool)
    {
        require(
            !isSuspended(_msgSender()) && !isSuspended(recipient),
            "OSLToken: Addresses must not be suspended"
        );
        require(
            _verifyWhitelist(_msgSender()) && _verifyWhitelist(recipient),
            "OSLToken: Addresses must be whitelisted"
        );

        return super.transfer(recipient, amount);
    }
}
