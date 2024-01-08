// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.6.12;

import "./Moartroller.sol";
import "./AbstractInterestRateModel.sol";

abstract contract MTokenStorage {
    /**
     * @dev Guard variable for re-entrancy checks
     */
    bool internal _notEntered;

    /**
     * @dev EIP-20 token name for this token
     */
    string public name;

    /**
     * @dev EIP-20 token symbol for this token
     */
    string public symbol;

    /**
     * @dev EIP-20 token decimals for this token
     */
    uint8 public decimals;

    /**
     * @notice Underlying asset for this MToken
     */
    address public underlying;

    /**
     * @dev Maximum borrow rate that can ever be applied (.0005% / block)
     */

    uint internal borrowRateMaxMantissa;

    /**
     * @dev Maximum fraction of interest that can be set aside for reserves
     */
    uint internal reserveFactorMaxMantissa;

    /**
     * @dev Administrator for this contract
     */
    address payable public admin;

    /**
     * @dev Pending administrator for this contract
     */
    address payable public pendingAdmin;

    /**
     * @dev Contract which oversees inter-mToken operations
     */
    Moartroller public moartroller;

    /**
     * @dev Model which tells what the current interest rate should be
     */
    AbstractInterestRateModel public interestRateModel;

    /**
     * @dev Initial exchange rate used when minting the first MTokens (used when totalSupply = 0)
     */
    uint internal initialExchangeRateMantissa;

    /**
     * @dev Fraction of interest currently set aside for reserves
     */
    uint public reserveFactorMantissa;

    /**
     * @dev Fraction of reserves currently set aside for other usage
     */
    uint public reserveSplitFactorMantissa;

    /**
     * @dev Block number that interest was last accrued at
     */
    uint public accrualBlockNumber;

    /**
     * @dev Accumulator of the total earned interest rate since the opening of the market
     */
    uint public borrowIndex;

    /**
     * @dev Total amount of outstanding borrows of the underlying in this market
     */
    uint public totalBorrows;

    /**
     * @dev Total amount of reserves of the underlying held in this market
     */
    uint public totalReserves;

    /**
     * @dev Total number of tokens in circulation
     */
    uint public totalSupply;

    /**
     * @dev The Maximum Protection Moarosition (MPC) factor for collateral optimisation, default: 50% = 5000
     */
    uint public maxProtectionComposition;

    /**
     * @dev The Maximum Protection Moarosition (MPC) mantissa, default: 1e5
     */
    uint public maxProtectionCompositionMantissa;

    /**
     * @dev Official record of token balances for each account
     */
    mapping (address => uint) internal accountTokens;

    /**
     * @dev Approved token transfer amounts on behalf of others
     */
    mapping (address => mapping (address => uint)) internal transferAllowances;

    struct ProtectionUsage {
        uint256 protectionValueUsed;
    }

    /**
     * @dev Container for borrow balance information
     * @member principal Total balance (with accrued interest), after applying the most recent balance-changing action
     * @member interestIndex Global borrowIndex as of the most recent balance-changing action
     */
    struct BorrowSnapshot {
        uint principal;
        uint interestIndex;
        mapping (uint256 => ProtectionUsage) protectionsUsed;
    }

    struct AccrueInterestTempStorage{
        uint interestAccumulated;
        uint reservesAdded;
        uint splitedReserves_1;
        uint splitedReserves_2;
        uint totalBorrowsNew;
        uint totalReservesNew;
        uint borrowIndexNew;
    }

    /**
     * @dev Mapping of account addresses to outstanding borrow balances
     */
    mapping(address => BorrowSnapshot) public accountBorrows;


}