/// SPDX-License-Identifier: BUSL-1.1

/// Copyright (C) 2023 Brahma.fi

pragma solidity 0.8.19;

import "./AddressProviderService.sol";
import "./WalletRegistry.sol";

/**
 * @title PolicyRegistry
 * @author Brahma.fi
 * @notice Registry for policy commits for wallets and sub accounts
 */
contract PolicyRegistry is AddressProviderService {
    error PolicyCommitInvalid();
    error UnauthorizedPolicyUpdate();

    event UpdatedPolicyCommit(address indexed account, bytes32 policyCommit, bytes32 oldPolicyCommit);

    /// @notice account addresses mapped to their policy commits
    mapping(address account => bytes32 policyCommit) public commitments;

    constructor(address _addressProvider) AddressProviderService(_addressProvider) {}

    /**
     * @notice Enables setting policy commits for accounts
     * @param account address of account to set policy commit for
     * @param policyCommit policy commit hash to set
     * @dev policyCommit for an account can be set by:
     *  1. by safe deployer, if the account is uninitialized
     *  2. by the registered wallet, if the account is a subAccount
     *  3. by the account itself, if account is a registered wallet
     */
    function updatePolicy(address account, bytes32 policyCommit) external {
        if (policyCommit == bytes32(0)) {
            revert PolicyCommitInvalid();
        }

        bytes32 currentCommit = commitments[account];

        // solhint-disable no-empty-blocks
        if (
            currentCommit == bytes32(0)
                && msg.sender == AddressProviderService._getAuthorizedAddress(_SAFE_DEPLOYER_HASH)
        ) {
            // In case invoker is safe  deployer
        } else {
            if (WalletRegistry(walletRegistry).subAccountToWallet(account) == msg.sender) {
                //In case invoker is updating on behalf of sub account
            } else if (msg.sender == account && WalletRegistry(walletRegistry).isWallet(msg.sender)) {
                // In case invoker is a registered wallet
            } else {
                revert UnauthorizedPolicyUpdate();
            }
        }
        // solhint-enable no-empty-blocks
        _updatePolicy(account, policyCommit, currentCommit);
    }

    /**
     * @notice Internal function to update policy commit for an account
     * @param account address of account to set policy commit for
     * @param policyCommit policy commit hash to set
     */
    function _updatePolicy(address account, bytes32 policyCommit, bytes32 oldPolicyCommit) internal {
        emit UpdatedPolicyCommit(account, policyCommit, oldPolicyCommit);
        commitments[account] = policyCommit;
    }
}
