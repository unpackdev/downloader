/// SPDX-License-Identifier: BUSL-1.1

/// Copyright (C) 2023 Brahma.fi

pragma solidity 0.8.19;

import "./AddressProviderService.sol";

/**
 * @title WalletRegistry
 * @author Brahma.fi
 * @notice Registry for wallet and sub account addresses
 */
contract WalletRegistry is AddressProviderService {
    error AlreadyRegistered();
    error InvalidSender();
    error IsSubAccount();

    event RegisterWallet(address indexed wallet);
    event RegisterSubAccount(address indexed wallet, address indexed subAccount);

    /// @notice subAccount addresses mapped to owner wallet
    mapping(address subAccount => address wallet) public subAccountToWallet;
    /// @notice wallet addresses mapped to list of subAccounts
    mapping(address wallet => address[] subAccountList) public walletToSubAccountList;
    /// @notice address of wallet mapped to boolean indicating if it's a wallet
    mapping(address => bool) public isWallet;

    constructor(address _addressProvider) AddressProviderService(_addressProvider) {}

    /**
     * @notice Registers a wallet
     * @dev Can only be called by wallet to register itself
     */
    function registerWallet() external {
        if (isWallet[msg.sender]) revert AlreadyRegistered();
        if (subAccountToWallet[msg.sender] != address(0)) revert IsSubAccount();
        isWallet[msg.sender] = true;
        emit RegisterWallet(msg.sender);
    }

    /**
     * @notice Registers a sub account for a Safe
     * @param _wallet Console account address, owner of sub account
     * @param _subAccount Sub account address to register
     * @dev Can only be called by safe deployer
     */

    function registerSubAccount(address _wallet, address _subAccount) external {
        if (msg.sender != AddressProviderService._getAuthorizedAddress(_SAFE_DEPLOYER_HASH)) revert InvalidSender();

        if (subAccountToWallet[_subAccount] != address(0) || isWallet[_subAccount]) revert AlreadyRegistered();

        subAccountToWallet[_subAccount] = _wallet;
        walletToSubAccountList[_wallet].push(_subAccount);
        emit RegisterSubAccount(_wallet, _subAccount);
    }

    /**
     * @notice sub account list getter
     * @dev returns sub account list associated with _wallet
     * @param _wallet safe address
     * @return list of subAccounts for wallet
     */
    function getSubAccountsForWallet(address _wallet) external view returns (address[] memory) {
        return walletToSubAccountList[_wallet];
    }
}
