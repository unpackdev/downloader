// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.5;

import "./Ownable.sol";

/// @title Whitelist
/// @notice contains a list of wallets allowed to perform a certain operation
contract Whitelist is Ownable {

    /// @notice struct containing information about a wallet
    struct WhitelistInfo {
        bool isWhitelisted;
        uint256 blockTimestamp;
    }
    mapping(address => WhitelistInfo) internal wallets;

    /// @notice events of approval and revoking wallets
    event ApproveWallet(address, uint256);
    event RevokeWallet(address, uint256);

    /// @notice approves wallet
    /// @param _wallet the wallet to approve
    function approveWallet(address _wallet, uint256 blockTimestamp) external onlyOwner {
        if (!wallets[_wallet].isWhitelisted) {
            wallets[_wallet].isWhitelisted = true;
            wallets[_wallet].blockTimestamp = blockTimestamp;
            emit ApproveWallet(_wallet, blockTimestamp);
        }
    }

    /// @notice revokes wallet
    /// @param _wallet the wallet to revoke
    function revokeWallet(address _wallet) external onlyOwner {
        if (wallets[_wallet].isWhitelisted) {
            wallets[_wallet].isWhitelisted = false;
            emit RevokeWallet(_wallet, wallets[_wallet].blockTimestamp);
        }
    }

    /// @notice checks if _wallet is whitelisted and blockTimestamp has passed
    /// @param _wallet the wallet to check
    /// @return true if wallet is whitelisted and blockTimestamp has passed
    function check(address _wallet) external view returns (bool) {
        return wallets[_wallet].isWhitelisted && block.timestamp >= wallets[_wallet].blockTimestamp;
    }
}
