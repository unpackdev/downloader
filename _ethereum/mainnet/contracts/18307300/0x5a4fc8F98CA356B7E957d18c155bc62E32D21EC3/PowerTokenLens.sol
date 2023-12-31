// SPDX-License-Identifier: BSD-3-Clause
// File: lib/ipor-power-tokens/contracts/libraries/errors/Errors.sol


pragma solidity 0.8.20;

library Errors {
    /// @notice Error thrown when the lpToken address is not supported
    /// @dev List of supported LpTokens is defined in {LiquidityMining._lpTokens}
    string public constant LP_TOKEN_NOT_SUPPORTED = "PT_701";
    /// @notice Error thrown when the caller / msgSender is not a Pause Manager address.
    /// @dev Pause Manager can be defined by the smart contract's Onwer
    string public constant CALLER_NOT_PAUSE_MANAGER = "PT_704";
    /// @notice Error thrown when the account's base balance is too low
    string public constant ACCOUNT_BASE_BALANCE_IS_TOO_LOW = "PT_705";
    /// @notice Error thrown when the account's Lp Token balance is too low
    string public constant ACCOUNT_LP_TOKEN_BALANCE_IS_TOO_LOW = "PT_706";
    /// @notice Error thrown when the account's delegated balance is too low
    string public constant ACC_DELEGATED_TO_LIQUIDITY_MINING_BALANCE_IS_TOO_LOW = "PT_707";
    /// @notice Error thrown when the account's available Power Token balance is too low
    string public constant ACC_AVAILABLE_POWER_TOKEN_BALANCE_IS_TOO_LOW = "PT_708";
    /// @notice Error thrown when the account doesn't have the rewards (Staked Tokens / Power Tokens) to claim
    string public constant NO_REWARDS_TO_CLAIM = "PT_709";
    /// @notice Error thrown when the cooldown is not finished.
    string public constant COOL_DOWN_NOT_FINISH = "PT_710";
    /// @notice Error thrown when the aggregate power up indicator is going to be negative during the calculation.
    string public constant AGGREGATE_POWER_UP_COULD_NOT_BE_NEGATIVE = "PT_711";
    /// @notice Error thrown when the block number used in the function is lower than previous block number stored in the liquidity mining indicators.
    string public constant BLOCK_NUMBER_LOWER_THAN_PREVIOUS_BLOCK_NUMBER = "PT_712";
    /// @notice Account Composite Multiplier indicator is greater or equal to Composit Multiplier indicator, but it should be lower or equal
    string public constant ACCOUNT_COMPOSITE_MULTIPLIER_GT_COMPOSITE_MULTIPLIER = "PT_713";
    /// @notice The fee for unstacking of Power Tokens should be number between (0, 1e18)
    string public constant UNSTAKE_WITHOUT_COOLDOWN_FEE_IS_TO_HIGH = "PT_714";
    /// @notice General problem, address is wrong
    string public constant WRONG_ADDRESS = "PT_715";
    /// @notice General problem, contract is wrong
    string public constant WRONG_CONTRACT_ID = "PT_716";
    /// @notice Value not greater than zero
    string public constant VALUE_NOT_GREATER_THAN_ZERO = "PT_717";
    /// @notice Appeared when input of two arrays length mismatch
    string public constant INPUT_ARRAYS_LENGTH_MISMATCH = "PT_718";
    /// @notice msg.sender is not an appointed owner, it cannot confirm their ownership
    string public constant SENDER_NOT_APPOINTED_OWNER = "PT_719";
    /// @notice msg.sender is not an appointed owner, it cannot confirm their ownership
    string public constant ROUTER_INVALID_SIGNATURE = "PT_720";
    string public constant INPUT_ARRAYS_EMPTY = "PT_721";
    string public constant CALLER_NOT_ROUTER = "PT_722";
    string public constant CALLER_NOT_GUARDIAN = "PT_723";
    string public constant CONTRACT_PAUSED = "PT_724";
    string public constant REENTRANCY = "PT_725";
    string public constant CALLER_NOT_OWNER = "PT_726";
}

// File: lib/ipor-power-tokens/contracts/libraries/ContractValidator.sol


pragma solidity 0.8.20;


library ContractValidator {
    function checkAddress(address addr) internal pure returns (address) {
        require(addr != address(0), Errors.WRONG_ADDRESS);
        return addr;
    }
}

// File: lib/ipor-power-tokens/contracts/interfaces/types/PowerTokenTypes.sol


pragma solidity 0.8.20;

/// @title Struct used across Liquidity Mining.
library PowerTokenTypes {
    struct PwTokenCooldown {
        // @dev The timestamp when the account can redeem Power Tokens
        uint256 endTimestamp;
        // @dev The amount of Power Tokens which can be redeemed without fee when the cooldown reaches `endTimestamp`
        uint256 pwTokenAmount;
    }

    struct UpdateGovernanceToken {
        address beneficiary;
        uint256 governanceTokenAmount;
    }
}

// File: lib/ipor-power-tokens/contracts/interfaces/IPowerTokenInternal.sol


pragma solidity 0.8.20;


/// @title PowerToken smart contract interface
interface IPowerTokenInternal {
    /// @notice Returns the current version of the PowerToken smart contract
    /// @return Current PowerToken smart contract version
    function getVersion() external pure returns (uint256);

    /// @notice Gets the total supply base amount
    /// @return total supply base amount, represented with 18 decimals
    function totalSupplyBase() external view returns (uint256);

    /// @notice Calculates the internal exchange rate between the Staked Token and total supply of a base amount
    /// @return Current exchange rate between the Staked Token and the total supply of a base amount, represented with 18 decimals.
    function calculateExchangeRate() external view returns (uint256);

    /// @notice Method for seting up the unstaking fee
    /// @param unstakeWithoutCooldownFee fee percentage, represented with 18 decimals.
    function setUnstakeWithoutCooldownFee(uint256 unstakeWithoutCooldownFee) external;

    /// @notice method returning address of the Staked Token
    function getGovernanceToken() external view returns (address);

    /// @notice Pauses the smart contract, it can only be executed by the Owner
    /// @dev Emits {Paused} event.
    function pause() external;

    /// @notice Unpauses the smart contract, it can only be executed by the Owner
    /// @dev Emits {Unpaused}.
    function unpause() external;

    /// @notice Method for granting allowance to the Router
    /// @param erc20Token address of the ERC20 token
    function grantAllowanceForRouter(address erc20Token) external;

    /// @notice Method for revoking allowance to the Router
    /// @param erc20Token address of the ERC20 token
    function revokeAllowanceForRouter(address erc20Token) external;

    /// @notice Gets the power token cool down time in seconds.
    /// @return uint256 cool down time in seconds
    function COOL_DOWN_IN_SECONDS() external view returns (uint256);

    /// @notice Adds a new pause guardian to the contract.
    /// @param guardians The addresses of the new pause guardians.
    /// @dev Only the contract owner can call this function.
    function addPauseGuardians(address[] calldata guardians) external;

    /// @notice Removes a pause guardian from the contract.
    /// @param guardians The addresses of the pause guardians to be removed.
    /// @dev Only the contract owner can call this function.
    function removePauseGuardians(address[] calldata guardians) external;

    /// @notice Checks if an address is a pause guardian.
    /// @param guardian The address to be checked.
    /// @return A boolean indicating whether the address is a pause guardian (true) or not (false).
    function isPauseGuardian(address guardian) external view returns (bool);

    /// @notice Emitted when the user receives rewards from the LiquidityMining
    /// @dev Receiving rewards does not change Internal Exchange Rate of Power Tokens in PowerToken smart contract.
    /// @param account address
    /// @param rewardsAmount amount of Power Tokens received from LiquidityMining
    event RewardsReceived(address account, uint256 rewardsAmount);

    /// @notice Emitted when the fee for immediate unstaking is modified.
    /// @param newFee new value of the fee, represented with 18 decimals
    event UnstakeWithoutCooldownFeeChanged(uint256 newFee);

    /// @notice Emmited when PauseManager's address had been changed by its owner.
    /// @param newLiquidityMining PauseManager's new address
    event LiquidityMiningChanged(address indexed newLiquidityMining);

    /// @notice Emmited when the PauseManager's address is changed by its owner.
    /// @param newPauseManager PauseManager's new address
    event PauseManagerChanged(address indexed newPauseManager);

    /// @notice Emitted when owner grants allowance for router
    /// @param erc20Token address of ERC20 token
    /// @param router address of router
    event AllowanceGranted(address indexed erc20Token, address indexed router);

    /// @notice Emitted when owner revokes allowance for router
    /// @param erc20Token address of ERC20 token
    /// @param router address of router
    event AllowanceRevoked(address indexed erc20Token, address indexed router);
}

// File: lib/ipor-power-tokens/contracts/interfaces/IPowerToken.sol


pragma solidity 0.8.20;


/// @title The Interface for the interaction with the PowerToken - smart contract responsible
/// for managing Power Token (pwToken), Swapping Staked Token for Power Tokens, and
/// delegating Power Tokens to other components.
interface IPowerToken {
    /// @notice Gets the name of the Power Token
    /// @return Returns the name of the Power Token.
    function name() external pure returns (string memory);

    /// @notice Contract ID. The keccak-256 hash of "io.ipor.PowerToken" decreased by 1
    /// @return Returns the ID of the contract
    function getContractId() external pure returns (bytes32);

    /// @notice Gets the symbol of the Power Token.
    /// @return Returns the symbol of the Power Token.
    function symbol() external pure returns (string memory);

    /// @notice Returns the number of the decimals used by Power Token. By default it's 18 decimals.
    /// @return Returns the number of decimals: 18.
    function decimals() external pure returns (uint8);

    /// @notice Gets the total supply of the Power Token.
    /// @dev Value is calculated in runtime using baseTotalSupply and internal exchange rate.
    /// @return Total supply of Power tokens, represented with 18 decimals
    function totalSupply() external view returns (uint256);

    /// @notice Gets the balance of Power Tokens for a given account
    /// @param account account address for which the balance of Power Tokens is fetched
    /// @return Returns the amount of the Power Tokens owned by the `account`.
    function balanceOf(address account) external view returns (uint256);

    /// @notice Gets the delegated balance of the Power Tokens for a given account.
    /// Tokens are delegated from PowerToken to LiquidityMining smart contract (reponsible for rewards distribution).
    /// @param account account address for which the balance of delegated Power Tokens is checked
    /// @return  Returns the amount of the Power Tokens owned by the `account` and delegated to the LiquidityMining contracts.
    function delegatedToLiquidityMiningBalanceOf(address account) external view returns (uint256);

    /// @notice Gets the rate of the fee from the configuration. This fee is applied when the owner of Power Tokens wants to unstake them immediately.
    /// @dev Fee value represented in as a percentage with 18 decimals
    /// @return value, a percentage represented with 18 decimal
    function getUnstakeWithoutCooldownFee() external view returns (uint256);

    /// @notice Gets the state of the active cooldown for the sender.
    /// @dev If PowerTokenTypes.PowerTokenCoolDown contains only zeros it represents no active cool down.
    /// Struct containing information on when the cooldown end and what is the quantity of the Power Tokens locked.
    /// @param account account address that owns Power Tokens in the cooldown
    /// @return Object PowerTokenTypes.PowerTokenCoolDown represents active cool down
    function getActiveCooldown(
        address account
    ) external view returns (PowerTokenTypes.PwTokenCooldown memory);

    /// @notice Initiates a cooldown for the specified account.
    /// @dev This function allows an account to initiate a cooldown period for a specified amount of Power Tokens.
    ///      During the cooldown period, the specified amount of Power Tokens cannot be redeemed or transferred.
    /// @param account The account address for which the cooldown is initiated.
    /// @param pwTokenAmount The amount of Power Tokens to be put on cooldown.
    function cooldownInternal(address account, uint256 pwTokenAmount) external;

    /// @notice Cancels the cooldown for the specified account.
    /// @dev This function allows an account to cancel the active cooldown period for their Power Tokens,
    ///      enabling them to freely redeem or transfer their Power Tokens.
    /// @param account The account address for which the cooldown is to be canceled.
    function cancelCooldownInternal(address account) external;

    /// @notice Redeems Power Tokens for the specified account.
    /// @dev This function allows an account to redeem their Power Tokens, transferring the specified
    ///      amount of Power Tokens back to the account's staked token balance.
    ///      The redemption is subject to the cooldown period, and the account must wait for the cooldown
    ///      period to finish before being able to redeem the Power Tokens.
    /// @param account The account address for which Power Tokens are to be redeemed.
    /// @return transferAmount The amount of Power Tokens that have been redeemed and transferred back to the staked token balance.
    function redeemInternal(address account) external returns (uint256 transferAmount);

    /// @notice Adds staked tokens to the specified account.
    /// @dev This function allows the specified account to add staked tokens to their Power Token balance.
    ///      The staked tokens are converted to Power Tokens based on the internal exchange rate.
    /// @param updateGovernanceToken An object of type PowerTokenTypes.UpdateGovernanceToken containing the details of the staked token update.
    function addGovernanceTokenInternal(
        PowerTokenTypes.UpdateGovernanceToken memory updateGovernanceToken
    ) external;

    /// @notice Removes staked tokens from the specified account, applying a fee.
    /// @dev This function allows the specified account to remove staked tokens from their Power Token balance,
    ///      while deducting a fee from the staked token amount. The fee is determined based on the cooldown period.
    /// @param updateGovernanceToken An object of type PowerTokenTypes.UpdateGovernanceToken containing the details of the staked token update.
    /// @return governanceTokenAmountToTransfer The amount of staked tokens to be transferred after applying the fee.
    function removeGovernanceTokenWithFeeInternal(
        PowerTokenTypes.UpdateGovernanceToken memory updateGovernanceToken
    ) external returns (uint256 governanceTokenAmountToTransfer);

    /// @notice Delegates a specified amount of Power Tokens from the caller's balance to the Liquidity Mining contract.
    /// @dev This function allows the caller to delegate a specified amount of Power Tokens to the Liquidity Mining contract,
    ///      enabling them to participate in liquidity mining and earn rewards.
    /// @param account The address of the account delegating the Power Tokens.
    /// @param pwTokenAmount The amount of Power Tokens to delegate.
    function delegateInternal(address account, uint256 pwTokenAmount) external;

    /// @notice Undelegated a specified amount of Power Tokens from the Liquidity Mining contract back to the caller's balance.
    /// @dev This function allows the caller to undelegate a specified amount of Power Tokens from the Liquidity Mining contract,
    ///      effectively removing them from participation in liquidity mining and stopping the earning of rewards.
    /// @param account The address of the account to undelegate the Power Tokens from.
    /// @param pwTokenAmount The amount of Power Tokens to undelegate.
    function undelegateInternal(address account, uint256 pwTokenAmount) external;

    /// @notice Emitted when the account stake/add [Staked] Tokens
    /// @param account account address that executed the staking
    /// @param governanceTokenAmount of Staked Token amount being staked into PowerToken contract
    /// @param internalExchangeRate internal exchange rate used to calculate the base amount
    /// @param baseAmount value calculated based on the governanceTokenAmount and the internalExchangeRate
    event GovernanceTokenAdded(
        address indexed account,
        uint256 governanceTokenAmount,
        uint256 internalExchangeRate,
        uint256 baseAmount
    );

    /// @notice Emitted when the account unstakes the Power Tokens
    /// @param account address that executed the unstaking
    /// @param pwTokenAmount amount of Power Tokens that were unstaked
    /// @param internalExchangeRate which was used to calculate the base amount
    /// @param fee amount subtracted from the pwTokenAmount
    event GovernanceTokenRemovedWithFee(
        address indexed account,
        uint256 pwTokenAmount,
        uint256 internalExchangeRate,
        uint256 fee
    );

    /// @notice Emitted when the sender delegates the Power Tokens to the LiquidityMining contract
    /// @param account address delegating the Power Tokens
    /// @param pwTokenAmounts amounts of Power Tokens delegated to respective lpTokens
    event Delegated(address indexed account, uint256 pwTokenAmounts);

    /// @notice Emitted when the sender undelegates Power Tokens from the LiquidityMining
    /// @param account address undelegating Power Tokens
    /// @param pwTokenAmounts amounts of Power Tokens undelegated form respective lpTokens
    event Undelegated(address indexed account, uint256 pwTokenAmounts);

    /// @notice Emitted when the sender sets the cooldown on Power Tokens
    /// @param pwTokenAmount amount of pwToken in cooldown
    /// @param endTimestamp end time of the cooldown
    event CooldownChanged(uint256 pwTokenAmount, uint256 endTimestamp);

    /// @notice Emitted when the sender redeems the pwTokens after the cooldown
    /// @param account address that executed the redeem function
    /// @param pwTokenAmount amount of the pwTokens that was transferred to the Power Token owner's address
    event Redeem(address indexed account, uint256 pwTokenAmount);
}

// File: lib/ipor-power-tokens/contracts/interfaces/IPowerTokenLens.sol


pragma solidity 0.8.20;


interface IPowerTokenLens {
    /// @notice Gets the total supply of the Power Token.
    /// @dev Value is calculated in runtime using baseTotalSupply and internal exchange rate.
    /// @return Total supply of Power tokens, represented with 18 decimals
    function totalSupplyOfPwToken() external view returns (uint256);

    /// @notice Gets the balance of Power Tokens for a given account
    /// @param account account address for which the balance of Power Tokens is fetched
    /// @return Returns the amount of the Power Tokens owned by the `account`.
    function balanceOfPwToken(address account) external view returns (uint256);

    /// @notice Gets the delegated balance of the Power Tokens for a given account.
    /// Tokens are delegated from PowerToken to LiquidityMining smart contract (reponsible for rewards distribution).
    /// @param account account address for which the balance of delegated Power Tokens is checked
    /// @return  Returns the amount of the Power Tokens owned by the `account` and delegated to the LiquidityMining contracts.
    function balanceOfPwTokenDelegatedToLiquidityMining(
        address account
    ) external view returns (uint256);

    /// @notice Gets the rate of the fee from the configuration. This fee is applied when the owner of Power Tokens wants to unstake them immediately.
    /// @dev Fee value represented in as a percentage with 18 decimals
    /// @return value, a percentage represented with 18 decimal
    function getPwTokenUnstakeFee() external view returns (uint256);

    /// @notice Gets the state of the active cooldown for the sender.
    /// @dev If PowerTokenTypes.PowerTokenCoolDown contains only zeros it represents no active cool down.
    /// Struct containing information on when the cooldown end and what is the quantity of the Power Tokens locked.
    /// @param account account address that owns Power Tokens in the cooldown
    /// @return Object PowerTokenTypes.PowerTokenCoolDown represents active cool down
    function getPwTokensInCooldown(
        address account
    ) external view returns (PowerTokenTypes.PwTokenCooldown memory);

    /// @notice Gets the power token cool down time in seconds.
    /// @return uint256 cool down time in seconds
    function getPwTokenCooldownTime() external view returns (uint256);

    /// @notice Calculates the internal exchange rate between the Staked Token and total supply of a base amount
    /// @return Current exchange rate between the Staked Token and the total supply of a base amount, represented with 18 decimals.
    function getPwTokenExchangeRate() external view returns (uint256);

    /// @notice Gets the total supply base amount
    /// @return total supply base amount, represented with 18 decimals
    function getPwTokenTotalSupplyBase() external view returns (uint256);
}

// File: lib/ipor-power-tokens/contracts/lens/PowerTokenLens.sol


pragma solidity 0.8.20;






/// @dev It is not recommended to use lens contract directly, should be used only through router (like IporProtocolRouter or PowerTokenRouter)
contract PowerTokenLens is IPowerTokenLens {
    using ContractValidator for address;
    address public immutable powerToken;

    constructor(address powerTokenInput) {
        powerToken = powerTokenInput.checkAddress();
    }

    function totalSupplyOfPwToken() external view override returns (uint256) {
        return IPowerToken(powerToken).totalSupply();
    }

    function balanceOfPwToken(address account) external view override returns (uint256) {
        return IPowerToken(powerToken).balanceOf(account);
    }

    function balanceOfPwTokenDelegatedToLiquidityMining(
        address account
    ) external view override returns (uint256) {
        return IPowerToken(powerToken).delegatedToLiquidityMiningBalanceOf(account);
    }

    function getPwTokenUnstakeFee() external view returns (uint256) {
        return IPowerToken(powerToken).getUnstakeWithoutCooldownFee();
    }

    function getPwTokensInCooldown(
        address account
    ) external view returns (PowerTokenTypes.PwTokenCooldown memory) {
        return IPowerToken(powerToken).getActiveCooldown(account);
    }

    function getPwTokenCooldownTime() external view returns (uint256) {
        return IPowerTokenInternal(powerToken).COOL_DOWN_IN_SECONDS();
    }

    function getPwTokenExchangeRate() external view returns (uint256) {
        return IPowerTokenInternal(powerToken).calculateExchangeRate();
    }

    function getPwTokenTotalSupplyBase() external view returns (uint256) {
        return IPowerTokenInternal(powerToken).totalSupplyBase();
    }
}