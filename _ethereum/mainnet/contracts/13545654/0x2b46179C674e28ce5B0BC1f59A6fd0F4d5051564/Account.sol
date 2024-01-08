// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./Governed.sol";
import "./Bank.sol";
import "./Market.sol";

/**
 * @title Helper to check the combined balance and do a combined withdrawal from several contracts
 */
contract Account is Governed {

    // Bank contract
    Bank public bank;

    // Market contract
    Market public market;

    /**
     * @param governanceAddress Address of the Governance contract
     *
     * Requirements:
     * - Governance contract must be deployed at the given address
     */
    constructor(address governanceAddress) Governed(governanceAddress) {}

    /**
     * @dev Sets the Bank contract address
     * @param bankAddress Address of the Bank contract
     *
     * Requirements:
     * - the caller must have the bootstrap permission
     */
    function setBankAddress(address bankAddress) external canBootstrap(msg.sender) {
        bank = Bank(bankAddress);
    }

    /**
     * @dev Sets the Market contract address
     * @param marketAddress Address of the Market contract
     *
     * Requirements:
     * - the caller must have the bootstrap permission
     */
    function setMarketAddress(address marketAddress) external canBootstrap(msg.sender) {
        market = Market(marketAddress);
    }

    /**
     * @dev Returns combined balance from bank and market contracts
     * @return uint
     */
    function getCombinedBalance() external view returns (uint) {
        return bank.getBalance(msg.sender) + market.payments(msg.sender);
    }

    /**
     * Withdraws the combined balance of bank and market contracts
     */
    function combinedWithdraw() external {
        bank.withdraw(payable(msg.sender));
        market.withdrawPayments(payable(msg.sender));
    }
}
