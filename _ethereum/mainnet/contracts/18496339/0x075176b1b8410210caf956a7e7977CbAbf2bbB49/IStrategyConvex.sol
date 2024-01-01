// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./IERC20Upgradeable.sol";
import "./IStrategyCalculations.sol";

/// @notice Interface for the Convex Strategy contract
interface IStrategyConvex {
    /// @dev Struct representing a pool token
    struct PoolToken {
        bool isAllowed; /// Flag indicating if the token is allowed
        uint8 index; /// Index of the token
    }

    /// @dev Struct representing an oracle
    struct Oracle {
        address token; /// Token address
        address oracle; /// Oracle address
    }

    /// @dev Struct representing default slippages
    struct DefaultSlippages {
        uint256 curve; /// Default slippage for Curve swaps
        uint256 uniswap; /// Default slippage for Uniswap swaps
    }

    /// @dev Struct representing reward information
    struct RewardInfo {
        address[] tokens; /// Array of reward tokens
        uint256[] minAmount; /// Array of minimum reward amounts
    }

    /// @dev Enum representing fee types
    enum FeeType {
        MANAGEMENT, /// Management fee
        PERFORMANCE /// Performance fee
    }

    /// @dev Event emitted when stucked tokens have been withdrawn
    /// @param caller Address of the caller of the transaction
    /// @param token Address of the token withdrawn
    /// @param amount Withdrawn amount
    event WithdrawStuckTokens(address caller, address token, uint256 amount);

    /// @dev Event emitted when a harvest is executed
    /// @param harvester The address of the harvester
    /// @param amount The amount harvested
    /// @param wantBal The balance of the want token after the harvest
    event Harvested(address indexed harvester, uint256 amount, uint256 wantBal);

    /// @dev Event emitted when a deposit is made
    /// @param user The address of the user
    /// @param token The address of the token deposited
    /// @param wantBal The balance of the want token generated with the deposit
    event Deposit(address user, address token, uint256 wantBal);

    /// @dev Event emitted when a withdrawal is made
    /// @param user The address of the user
    /// @param token The address of the token being withdrawn
    /// @param amount The amount withdrawn
    /// @param wantBal The balance of the want token after the withdrawal
    event Withdraw(address user, address token, uint256 amount, uint256 wantBal);

    /// @dev Event emitted when rewards are claimed
    /// @param user The address of the user
    /// @param token The address of the reward token
    /// @param amount The amount of rewards claimed
    /// @param wantBal The balance of the want token after claiming rewards
    event ClaimedRewards(address user, address token, uint256 amount, uint256 wantBal);

    /// @dev Event emitted when fees are charged
    /// @param feeType The type of fee (Management or Performance)
    /// @param amount The amount of fees charged
    /// @param feeRecipient The address of the fee recipient
    event ChargedFees(FeeType indexed feeType, uint256 amount, address feeRecipient);

    /// @dev Event emitted when allowed tokens are edited
    /// @param token The address of the token
    /// @param status The new status (true or false)
    event EditedAllowedTokens(address token, bool status);

    /// @dev Event emitted when the pause status is changed
    /// @param status The new pause status (true or false)
    event PauseStatusChanged(bool status);

    /// @dev Event emitted when a swap path is set
    /// @param from The address of the token to swap from
    /// @param to The address of the token to swap to
    /// @param path The swap path
    event SetPath(address from, address to, bytes path);

    /// @dev Event emitted when a swap route is set
    /// @param from The address of the token to swap from
    /// @param to The address of the token to swap to
    /// @param route The swap route
    event SetRoute(address from, address to, address[] route);

    /// @dev Event emitted when an oracle is set
    /// @param token The address of the token
    /// @param oracle The address of the oracle
    event SetOracle(address token, address oracle);

    /// @dev Event emitted when the slippage value is set
    /// @param oldValue The old slippage value
    /// @param newValue The new slippage value
    /// @param kind The kind of slippage (Curve or Uniswap)
    event SetSlippage(uint256 oldValue, uint256 newValue, string kind);

    /// @dev Event emitted when the minimum amount to harvest is changed
    /// @param token The address of the token
    /// @param minimum The new minimum amount to harvest
    event MinimumToHarvestChanged(address token, uint256 minimum);

    /// @dev Event emitted when a reward token is added
    /// @param token The address of the reward token
    /// @param minimum The minimum amount of the reward token
    event AddedRewardToken(address token, uint256 minimum);

    /// @dev Event emitted when a panic is executed
    event PanicExecuted();
}

/// @notice Extended interface for the Convex Strategy contract
interface IStrategyConvexExtended is IStrategyConvex {
    /// @dev Returns the address of the pool contract
    /// @return The address of the pool contract
    function pool() external view returns (address);

    /// @dev Returns how many tokens the pool accepts
    /// @return The number of tokens the pool accepts
    function POOL_SIZE() external view returns (uint256);

    /// @dev Returns the address of the calculations contract
    /// @return The address of the calculations contract
    function calculations() external view returns (IStrategyCalculations);

    /// @dev Returns the address of the admin structure contract
    /// @return The address of the admin structure contract
    function adminStructure() external view returns (address);

    /// @dev Minimum amount to execute reinvestment in harvest
    function minimumToHarvest(address _token) external view returns (uint256);

    /// @dev Executes the harvest operation, it is also the function compound, reinvests rewards
    function harvest() external;

    /// @dev Executes the harvest operation on deposits, it is also the function compound, reinvests rewards
    function harvestOnDeposit() external;

    /// @dev Handles the case where tokens get stuck in the Strategy. Allows the admin to send the tokens to the
    ///      SuperAdmin
    /// @param _token The address of the stuck token
    function inCaseTokensGetStuck(address _token) external;

    /// @dev Executes a panic operation, withdraws all the rewards from convex
    function panic() external;

    /// @dev Pauses the strategy, pauses deposits
    function pause() external;

    /// @dev Unpauses the strategy
    function unpause() external;

    /// @dev Withdraws tokens from the strategy
    /// @param _user The address of the user
    /// @param _amount The amount of tokens to withdraw
    /// @param _token The address of the token to withdraw
    /// @param _minCurveOutput The minimum LP output from Curve
    /// @param _useEth Indicates whether to withdraw ETH or not
    function withdraw(
        address _user,
        uint256 _amount,
        address _token,
        uint256 _minCurveOutput,
        bool _useEth
    ) external;

    /// @dev Claims rewards for the user
    /// @param _user The address of the user
    /// @param _token The address of the reward token
    /// @param _amount The amount of rewards to claim
    /// @param _minCurveOutput The minimum LP token output from Curve swap
    /// @param _useEth Indicates whether to withdraw ETH or not
    function claimRewards(
        address _user,
        address _token,
        uint256 _amount,
        uint256 _minCurveOutput,
        bool _useEth
    ) external;

    /// @dev Returns the address of the reward pool contract
    /// @return The address of the reward pool contract
    function rewardPool() external view returns (address);

    /// @dev Returns the address of the deposit token
    /// @return The address of the deposit token
    function depositToken() external view returns (address);

    /// @dev Checks if a token is allowed for deposit
    /// @param token The address of the token
    /// @return isAllowed True if the token is allowed, false otherwise
    /// @return index The index of the token
    function allowedDepositTokens(address token) external view returns (bool, uint8);

    /// @dev Returns the swap path for a token pair
    /// @param _from The address of the token to swap from
    /// @param _to The address of the token to swap to
    /// @return The swap path
    function paths(address _from, address _to) external view returns (bytes memory);

    /// @dev Returns the want deposit amount of a user in the deposit token
    /// @param _user The address of the user
    /// @return The deposit amount for the user
    function userWantDeposit(address _user) external view returns (uint256);

    /// @dev Returns the total want deposits in the strategy
    /// @return The total deposits in the strategy
    function totalWantDeposits() external view returns (uint256);

    /// @dev Returns the oracle address for a token
    /// @param _token The address of the token
    /// @return The oracle address
    function oracle(address _token) external view returns (address);

    /// @dev Returns the default slippage for Curve swaps used in harvest
    /// @return The default slippage for Curve swaps
    function defaultSlippageCurve() external view returns (uint256);

    /// @dev Returns the default slippage for Uniswap swaps used in harvest
    /// @return The default slippage for Uniswap swaps
    function defaultSlippageUniswap() external view returns (uint256);

    /// @dev Returns the want token
    /// @return The want token
    function want() external view returns (IERC20Upgradeable);

    /// @dev Returns the balance of the strategy held in the strategy
    /// @return The balance of the strategy
    function balanceOf() external view returns (uint256);

    /// @dev Returns the balance of the want token held in the strategy
    /// @return The balance of the want token
    function balanceOfWant() external view returns (uint256);

    /// @dev Returns the balance of want in the strategy
    /// @return The balance of the pool
    function balanceOfPool() external view returns (uint256);

    /// @dev Returns the pause status of the strategy
    /// @return True if the strategy is paused, false otherwise
    function paused() external view returns (bool);

    /// @dev Returns the address of the weth token
    /// @return The address of the weth router
    function weth() external view returns (address);

    /// @dev Returns the address of the Uniswap router
    /// @return The address of the Uniswap router
    function unirouter() external view returns (address);

    /// @dev Returns the address of the vault contract
    /// @return The address of the vault contract
    function vault() external view returns (address);

    /// @dev Returns the address of Convex booster
    /// @return The address of the Convex booster
    function booster() external view returns (address);

    /// @dev Returns the address of Uniswap V2 router
    /// @return The address of Uniswap V2 router
    function unirouterV2() external view returns (address);

    /// @dev Returns the address of Uniswap V3 router
    /// @return The address of Uniswap V3 router
    function unirouterV3() external view returns (address);

    /// @dev Returns the performance fee
    /// @return The performance fee
    function performanceFee() external view returns (uint256);

    /// @dev Returns the management fee
    /// @return The management fee
    function managementFee() external view returns (uint256);

    /// @dev Returns the performance fee recipient
    /// @return The performance fee recipient
    function performanceFeeRecipient() external view returns (address);

    /// @dev Returns the management fee recipient
    /// @return The management fee recipient
    function managementFeeRecipient() external view returns (address);

    /// @dev Returns the fee cap
    /// @return The fee cap
    function FEE_CAP() external view returns (uint256);

    /// @dev Returns the constant value of 100
    /// @return The constant value of 100
    function ONE_HUNDRED() external view returns (uint256);

    /// @dev Sets the performance fee
    /// @param _fee The new performance fee
    function setPerformanceFee(uint256 _fee) external;

    /// @dev Sets the management fee
    /// @param _fee The new management fee
    function setManagementFee(uint256 _fee) external;

    /// @dev Sets the performance fee recipient
    /// @param recipient The new performance fee recipient
    function setPerformanceFeeRecipient(address recipient) external;

    /// @dev Sets the management fee recipient
    /// @param recipient The new management fee recipient
    function setManagementFeeRecipient(address recipient) external;

    /// @dev Sets the vault contract
    /// @param _vault The address of the vault contract
    function setVault(address _vault) external;

    /// @dev Sets the Uniswap V2 router address
    /// @param _unirouterV2 The address of the Uniswap V2 router
    function setUnirouterV2(address _unirouterV2) external;

    /// @dev Sets the Uniswap V3 router address
    /// @param _unirouterV3 The address of the Uniswap V3 router
    function setUnirouterV3(address _unirouterV3) external;

    /// @notice Retrieves information about the pending rewards to harvest from the convex pool
    /// @return _rewardAmounts rewards the amount representing the pending rewards
    /// @return _rewardTokens addresses of the reward tokens
    /// @return _enoughRewards list indicating if the reward token is enough to harvest
    /// @return _atLeastOne indicates if there is at least one reward to harvest
    function getPendingToHarvest()
        external
        returns (
            uint256[] memory _rewardAmounts,
            address[] memory _rewardTokens,
            bool[] memory _enoughRewards,
            bool _atLeastOne
        );

    // List of the reward tokens
    function getRewardTokens() external view returns (address[] memory);
}

/// @title IStrategyConvexNonPayable
/// @notice Extended interface for the Convex Strategy contract
interface IStrategyConvexNonPayable is IStrategyConvexExtended {
    /// @dev Deposits tokens into the strategy
    /// @param _token The address of the token to deposit
    /// @param _amount Amount of tokens to deposit
    /// @param _user The address of the user
    /// @param _minWant The minimum amount of want tokens to get from curve
    function deposit(address _token, uint256 _amount, address _user, uint256 _minWant) external;
}

/// @title IStrategyConvexPayable
/// @notice Extended interface for the Convex Strategy contract
interface IStrategyConvexPayable is IStrategyConvexExtended {
    /// @dev Deposits tokens into the strategy
    /// @param _token The address of the token to deposit
    /// @param _amount Amount of tokens to deposit
    /// @param _user The address of the user
    /// @param _minWant The minimum amount of want tokens to get from curve
    function deposit(
        address _token,
        uint256 _amount,
        address _user,
        uint256 _minWant
    ) external payable;
}
