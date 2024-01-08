// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

library DataTypes {
    /**
     * @notice Container for User Deposit/withdraw operations
     * @param account User's address
     * @param isDeposit True if it is deposit and false if it withdraw
     * @param value Amount to deposit/withdraw
     */
    struct UserDepositOperation {
        address account;
        uint256 value;
    }

    /**
     * @notice Container for token balance in vault contract in a specific block
     * @param actualVaultValue current balance of the vault contract
     * @param blockMinVaultValue minimum balance recorded for vault contract in the same block
     * @param blockMaxVaultValue maximum balance recorded for vault contract in the same block
     */
    struct BlockVaultValue {
        uint256 actualVaultValue;
        uint256 blockMinVaultValue;
        uint256 blockMaxVaultValue;
    }

    /**
     * @notice Container for Strategy Steps used by Strategy
     * @param pool Liquidity Pool address
     * @param outputToken Output token of the liquidity pool
     * @param isBorrow If borrow is allowed or not for the liquidity pool
     */
    struct StrategyStep {
        address pool;
        address outputToken;
        bool isBorrow;
    }

    /**
     * @notice Container for pool's configuration
     * @param rating Rating of the liquidity pool
     * @param isLiquidityPool If pool is enabled as liquidity pool
     */
    struct LiquidityPool {
        uint8 rating;
        bool isLiquidityPool;
    }

    /**
     * @notice Container for Strategy used by Vault contract
     * @param index Index at which strategy is stored
     * @param strategySteps StrategySteps consisting pool, outputToken and isBorrow
     */
    struct Strategy {
        uint256 index;
        StrategyStep[] strategySteps;
    }

    /**
     * @notice Container for all Tokens
     * @param index Index at which token is stored
     * @param tokens List of token addresses
     */
    struct Token {
        uint256 index;
        address[] tokens;
    }

    /**
     * @notice Container for pool and its rating
     * @param pool Address of liqudity pool
     * @param rate Value to be set as rate for the liquidity pool
     */
    struct PoolRate {
        address pool;
        uint8 rate;
    }

    /**
     * @notice Container for mapping the liquidity pool and adapter
     * @param pool liquidity pool address
     * @param adapter adapter contract address corresponding to pool
     */
    struct PoolAdapter {
        address pool;
        address adapter;
    }

    /**
     * @notice Container for having limit range for the pools
     * @param lowerLimit liquidity pool rate's lower limit
     * @param upperLimit liquidity pool rate's upper limit
     */
    struct PoolRatingsRange {
        uint8 lowerLimit;
        uint8 upperLimit;
    }

    /**
     * @notice Container for having limit range for withdrawal fee
     * @param lowerLimit withdrawal fee's lower limit
     * @param upperLimit withdrawal fee's upper limit
     */
    struct WithdrawalFeeRange {
        uint256 lowerLimit;
        uint256 upperLimit;
    }

    /**
     * @notice Container for containing risk Profile's configuration
     * @param index Index at which risk profile is stored
     * @param canBorrow True if borrow is allowed for the risk profile
     * @param poolRatingsRange Container for having limit range for the pools
     * @param exists if risk profile exists or not
     */
    struct RiskProfile {
        uint256 index;
        bool canBorrow;
        PoolRatingsRange poolRatingsRange;
        bool exists;
        string name;
        string symbol;
    }

    /**
     * @notice Container for holding percentage of reward token to hold and convert
     * @param hold reward token hold percentage in basis point
     * @param convert reward token convert percentage in basis point
     */
    struct VaultRewardStrategy {
        uint256 hold; //  should be in basis eg: 50% means 5000
        uint256 convert; //  should be in basis eg: 50% means 5000
    }

    /** @notice Named Constants for defining max exposure state */
    enum MaxExposure { Number, Pct }

    /** @notice Named Constants for defining default strategy state */
    enum DefaultStrategyState { Zero, CompoundOrAave }

    /**
     * @notice Container for persisting ODEFI contract's state
     * @param index The market's last index
     * @param timestamp The block number the index was last updated at
     */
    struct RewardsState {
        uint224 index;
        uint32 timestamp;
    }

    /**
     * @notice Container for Treasury accounts along with their shares
     * @param treasury treasury account address
     * @param share treasury's share in percentage from the withdrawal fee
     */
    struct TreasuryShare {
        address treasury;
        uint256 share; //  should be in basis eg: 5% means 500
    }

    /**
     * @notice Container for combining Vault contract's configuration
     * @param discontinued If the vault contract is discontinued or not
     * @param unpaused If the vault contract is paused or unpaused
     * @param withdrawalFee withdrawal fee for a particular vault contract
     * @param treasuryShares Treasury accounts along with their shares
     * @param isLimitedState If the vault contract has a limit for total user deposits
     * @param allowWhitelistedState If the vault contract require whitelisted users or not
     * @param userDepositCap Maximum total amount that can be deposited by an address
     * @param minimumDepositAmount Minimum deposit without rebalance allowed
     * @param totalValueLockedLimitInUnderlying Maximum TVL in underlying allowed for the vault
     * @param queueCap Maximum length of the deposits without rebalance queue
     */
    struct VaultConfiguration {
        bool discontinued;
        bool unpaused;
        bool isLimitedState;
        bool allowWhitelistedState;
        TreasuryShare[] treasuryShares;
        uint256 withdrawalFee; //  should be in basis eg: 15% means 1500
        uint256 userDepositCap;
        uint256 minimumDepositAmount;
        uint256 totalValueLockedLimitInUnderlying;
        uint256 queueCap;
    }

    /**
     * @notice Container for persisting all strategy related contract's configuration
     * @param investStrategyRegistry investStrategyRegistry contract address
     * @param strategyProvider strategyProvider contract address
     * @param aprOracle aprOracle contract address
     */
    struct StrategyConfiguration {
        address investStrategyRegistry;
        address strategyProvider;
        address aprOracle;
    }

    /**
     * @notice Container for persisting contract addresses required by vault contract
     * @param strategyManager strategyManager contract address
     * @param riskManager riskManager contract address
     * @param optyDistributor optyDistributor contract address
     * @param operator operator contract address
     */
    struct VaultStrategyConfiguration {
        address strategyManager;
        address riskManager;
        address optyDistributor;
        address odefiVaultBooster;
        address operator;
    }
}
