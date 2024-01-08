// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./Governed.sol";
import "./OwnerBalanceContributor.sol";

/**
 * @title Tracks owner's share of the funds in various Macabris contracts
 */
contract OwnerBalance is Governed {

    address public owner;

    // All three contracts, that contribute to the owner's balance
    OwnerBalanceContributor public release;
    OwnerBalanceContributor public bank;
    OwnerBalanceContributor public market;

    /**
     * @param governanceAddress Address of the Governance contract
     *
     * Requirements:
     * - Governance contract must be deployed at the given address
     */
    constructor(address governanceAddress) Governed(governanceAddress) {}

    /**
     * @dev Sets the release contract address
     * @param releaseAddress Address of the Release contract
     *
     * Requirements:
     * - the caller must have the bootstrap permission
     */
    function setReleaseAddress(address releaseAddress) external canBootstrap(msg.sender) {
        release = OwnerBalanceContributor(releaseAddress);
    }

    /**
     * @dev Sets Bank contract address
     * @param bankAddress Address of the Bank contract
     *
     * Requirements:
     * - the caller must have the bootstrap permission
     */
    function setBankAddress(address bankAddress) external canBootstrap(msg.sender) {
        bank = OwnerBalanceContributor(bankAddress);
    }

    /**
     * @dev Sets the market contract address
     * @param marketAddress Address of the Market contract
     *
     * Requirements:
     * - the caller must have the bootstrap permission
     */
    function setMarketAddress(address marketAddress) external canBootstrap(msg.sender) {
        market = OwnerBalanceContributor(marketAddress);
    }

    /**
     * @dev Sets owner address where the funds will be sent during withdrawal
     * @param _owner Owner's address
     *
     * Requirements:
     * - sender must have canSetOwnerAddress permission
     * - address must not be 0
     */
    function setOwner(address _owner) external canSetOwnerAddress(msg.sender) {
        require(_owner != address(0), "Empty owner address is not allowed!");
        owner = _owner;
    }

    /**
     * @dev Returns total available balance in all contributing contracts
     * @return Balance in wei
     */
    function getBalance() external view returns (uint) {
        uint balance;

        balance += release.ownerBalanceDeposits();
        balance += bank.ownerBalanceDeposits();
        balance += market.ownerBalanceDeposits();

        return balance;
    }

    /**
     * @dev Withdraws available balance to the owner address
     *
     * Requirements:
     * - owner address must be set
     * - sender must have canTriggerOwnerWithdraw permission
     */
    function withdraw() external canTriggerOwnerWithdraw(msg.sender) {
        require(owner != address(0), "Owner address is not set");

        release.withdrawOwnerBalanceDeposits(owner);
        bank.withdrawOwnerBalanceDeposits(owner);
        market.withdrawOwnerBalanceDeposits(owner);
    }
}
