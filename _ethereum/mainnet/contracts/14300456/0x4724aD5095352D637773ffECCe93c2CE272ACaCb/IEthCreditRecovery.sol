// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

/**
 * @title IEthCreditRecovery
 *
 * @notice Handles the operation of Seen.Haus auctions.
 *
 * The ERC-165 identifier for this interface is: 0x78a6c477
 *
 */
interface IEthCreditRecovery {

    // Events
    event EthCreditRecovered(address indexed creditAddress, uint256 amount);
    event EthCreditFallbackRecovered(address indexed creditAddress, uint256 amount, address indexed admin, address indexed multisig);
    
    /**
     * @notice Enables recovery of any ETH credit to an account which has credits
     *
     * See: {MarketHandlerBase.sendValueOrCreditAccount}
     *
     * Credits are not specific to auctions (i.e. any sale credits would be distributed by this function too)
     *
     * Reverts if:
     * - Account has no ETH credits
     * - ETH cannot be sent to creditted account
     *
     * @param _recipient - address to distribute credits for
     */
    function recoverEthCredits(address _recipient) external;

    /**
     * @notice Enables admin recovery of any ETH credit for an account which has credits but can't recover the ETH via distributeEthCredits
     *
     * In rare cases, `_originalRecipient` may be unable to start receiving ETH again
     * therefore any ETH credits would get stuck
     *
     * See: {MarketHandlerBase.sendValueOrCreditAccount} & {EthCreditFacet.distributeEthCredits}
     *
     * Reverts if:
     * - Account has no ETH credits
     * - ETH cannot be sent to creditted account
     *
     * @param _originalRecipient - the account with unrecoverable (via distributeEthCredits) ETH credits
     */
    function fallbackRecoverEthCredit(address _originalRecipient) external;

    /**
     * @notice returns the pending ETH credits for a recipient
     *
     * @param _recipient - the account to check ETH credits for
     */
    function availableCredits(address _recipient) external view returns (uint256);
}