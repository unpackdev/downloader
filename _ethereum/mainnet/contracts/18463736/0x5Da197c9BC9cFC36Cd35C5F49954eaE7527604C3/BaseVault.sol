// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "./VaultTypes.sol";
import "./ERC20.sol";
import "./ReentrancyGuard.sol";
import "./IStrategy.sol";

import "./OwnableRoles.sol";
import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./FixedPointMathLib.sol";
import "./SafeTransferLib.sol";

/// @title MaxApy Base Vault Contract
/// @notice Stores data and executes generic logic for MaxApy vaults
/// @author MaxApy
contract BaseVault is ERC20, OwnableRoles, ReentrancyGuard {
    using SafeTransferLib for address;

    ////////////////////////////////////////////////////////////////
    ///                         CONSTANTS                        ///
    ////////////////////////////////////////////////////////////////

    uint256 public constant MAXIMUM_STRATEGIES = 20;
    uint256 public constant MAX_BPS = 10_000;
    uint256 public constant DEGRADATION_COEFFICIENT = 1e18;
    uint256 public constant SECS_PER_YEAR = 31_556_952;
    /// 365.2425 days

    /// Roles
    uint256 public constant ADMIN_ROLE = _ROLE_0;
    uint256 public constant EMERGENCY_ADMIN_ROLE = _ROLE_1;
    uint256 public constant STRATEGY_ROLE = _ROLE_2;

    ////////////////////////////////////////////////////////////////
    ///                         ERRORS                           ///
    ////////////////////////////////////////////////////////////////
    error QueueIsFull();
    error VaultInEmergencyShutdownMode();
    error StrategyInEmergencyExitMode();
    error InvalidZeroAddress();
    error StrategyAlreadyActive();
    error StrategyNotActive();
    error InvalidStrategyVault();
    error InvalidStrategyUnderlying();
    error InvalidDebtRatio();
    error InvalidMinDebtPerHarvest();
    error InvalidPerformanceFee();
    error InvalidManagementFee();
    error InvalidLockedProfitDegradation();
    error StrategyDebtRatioAlreadyZero();
    error InvalidQueueOrder();
    error VaultDepositLimitExceeded();
    error InvalidZeroAmount();
    error InvalidZeroShares();
    error InvalidMaxLoss();
    error MaxLossReached();
    error LossGreaterThanStrategyTotalDebt();
    error InvalidReportedGainAndDebtPayment();
    error FeesAlreadyAssesed();

    ////////////////////////////////////////////////////////////////
    ///                         EVENTS                           ///
    ////////////////////////////////////////////////////////////////

    /// @notice Emitted when a strategy is newly added to the protocol
    event StrategyAdded(
        address indexed newStrategy,
        uint16 strategyDebtRatio,
        uint128 strategyMaxDebtPerHarvest,
        uint128 strategyMinDebtPerHarvest,
        uint16 strategyPerformanceFee
    );

    /// @notice Emitted when a strategy is removed from the protocol
    event StrategyAdded(address indexed strategy);

    /// @notice Emitted when a vault's emergency shutdown state is switched
    event EmergencyShutdownUpdated(bool emergencyShutdown);

    /// @notice Emitted when a strategy is revoked from the vault
    event StrategyRevoked(address indexed strategy);

    /// @notice Emitted when a strategy parameters are updated
    event StrategyUpdated(
        address indexed strategy,
        uint16 newDebtRatio,
        uint128 newMaxDebtPerHarvest,
        uint128 newMinDebtPerHarvest,
        uint16 newPerformanceFee
    );

    /// @notice Emitted when the withdrawal queue is updated
    event WithdrawalQueueUpdated(address[MAXIMUM_STRATEGIES] withdrawalQueue);

    /// @notice Emitted when the vault's performance fee is updated
    event PerformanceFeeUpdated(uint16 newPerformanceFee);

    /// @notice Emitted when the vault's management fee is updated
    event ManagementFeeUpdated(uint256 newManagementFee);

    /// @notice Emitted the vault's locked profit degradation is updated
    event LockedProfitDegradationUpdated(uint256 newLockedProfitDegradation);

    /// @notice Emitted when the vault's deposit limit is updated
    event DepositLimitUpdated(uint256 newDepositLimit);

    /// @notice Emitted when the vault's treasury addresss is updated
    event TreasuryUpdated(address treasury);

    /// @notice Emitted on vault deposits
    event Deposit(address indexed recipient, uint256 shares, uint256 amount);

    /// @notice Emitted on vault withdrawals
    event Withdraw(address indexed recipient, uint256 shares, uint256 amount);

    /// @notice Emitted on withdrawal strategy withdrawals
    event WithdrawFromStrategy(address indexed strategy, uint128 strategyTotalDebt, uint128 loss);

    /// @notice Emitted after assessing protocol fees
    event FeesReported(uint256 managementFee, uint16 performanceFee, uint256 strategistFee, uint256 duration);

    /// @notice Emitted after a strategy reports to the vault
    event StrategyReported(
        address indexed strategy,
        uint256 gain,
        uint256 loss,
        uint256 debtPayment,
        uint128 strategyTotalGain,
        uint128 strategyTotalLoss,
        uint128 strategyTotalDebt,
        uint256 credit,
        uint16 strategyDebtRatio
    );

    // EVENT SIGNATURES

    uint256 internal constant _STRATEGY_ADDED_EVENT_SIGNATURE =
        0x66277e61c003f7703009ad857a4c4900f9cd3ee44535afe5905f98d53922e0f4;

    uint256 internal constant _STRATEGY_REMOVED_EVENT_SIGNATURE =
        0x3f008fd510eae7a9e7bee13513d7b83bef8003d488b5a3d0b0da4de71d6846f1;

    uint256 internal constant _EMERGENCY_SHUTDOWN_UPDATED_EVENT_SIGNATURE =
        0xa63137c77816d51f856c11ffb11e84757ac9db0ce2569f94edd04c91fe2250a1;

    uint256 internal constant _STRATEGY_REVOKED_EVENT_SIGNATURE =
        0x4201c688d84c01154d321afa0c72f1bffe9eef53005c9de9d035074e71e9b32a;

    uint256 internal constant _STRATEGY_UPDATED_EVENT_SIGNATURE =
        0x102a33a8369310733322056f2c0f753209cd77c65b1ce5775c2d6f181e38778f;

    uint256 internal constant _WITHDRAWAL_QUEUE_UPDATED_EVENT_SIGNATURE =
        0x92fa0b6a2861480bf8c9977f0f9fe1d95c535ba23cbf234f2716fc765aec3be8;

    uint256 internal constant _PERFORMANCE_FEE_UPDATED_EVENT_SIGNATURE =
        0x0632b4ddf7c06e7e3bc19b7ce92862c7de91b312a392142116fb574a06a47cfd;

    uint256 internal constant _MANAGEMENT_FEE_UPDATED_EVENT_SIGNATURE =
        0x2147e2bc8c39e67f74b1a9e08896ea1485442096765942206af1f4bc8bcde917;

    uint256 internal constant _LOCKED_PROFIT_DEGRADATION_UPDATED_EVENT_SIGNATURE =
        0x056863905a721211fc4dda1d688efc8f120b4b689d2e41da8249cf6eff200691;

    uint256 internal constant _DEPOSIT_LIMIT_UPDATED_EVENT_SIGNATURE =
        0xc512617347fd848ec9d7347c99c10e4fa7059132c92d0445930a7fb0c8252ff5;

    uint256 internal constant _TREASURY_UPDATED_EVENT_SIGNATURE =
        0x7dae230f18360d76a040c81f050aa14eb9d6dc7901b20fc5d855e2a20fe814d1;

    uint256 internal constant _DEPOSIT_EVENT_SIGNATURE =
        0x90890809c654f11d6e72a28fa60149770a0d11ec6c92319d6ceb2bb0a4ea1a15;

    uint256 internal constant _WITHDRAW_EVENT_SIGNATURE =
        0xf279e6a1f5e320cca91135676d9cb6e44ca8a08c0b88342bcdb1144f6511b568;

    uint256 internal constant _WITHDRAW_FROM_STRATEGY_EVENT_SIGNATURE =
        0x8c1171ccd065c6769e1540f65c3c0874e5f7173ccdff7ca293238e69d000bf20;

    uint256 internal constant _FEES_REPORTED_EVENT_SIGNATURE =
        0x25bf703141a84375d04ea08a0c4a21c7406f300f133e12aef555607b4f3ff238;

    uint256 internal constant _STRATEGY_REPORTED_EVENT_SIGNATURE =
        0xc2d7e1173e37528dce423c72b129fa1ad2c5d51e50974c64fe13f1928eb27f89;

    ////////////////////////////////////////////////////////////////
    ///               VAULT GLOBAL STATE VARIABLES               ///
    ////////////////////////////////////////////////////////////////

    /// @notice The vault underlying asset
    IERC20 public underlyingAsset;

    /// @notice Vault state stating if vault is in emergency shutdown mode
    bool public emergencyShutdown;
    /// @notice Limit for totalAssets the Vault can hold
    uint256 public depositLimit;
    /// @notice Debt ratio for the Vault across all strategies (in BPS, <= 10k)
    uint256 public debtRatio;
    /// @notice Amount of tokens that are in the vault
    uint256 public totalIdle;
    /// @notice Amount of tokens that all strategies have borrowed
    uint256 public totalDebt;
    /// @notice block.timestamp of last report
    uint256 public lastReport;
    /// @notice How much profit is locked and cant be withdrawn
    uint256 public lockedProfit;
    /// @notice Rate per block of degradation. DEGRADATION_COEFFICIENT is 100% per block
    uint256 public lockedProfitDegradation;
    /// @notice Rewards address where performance and management fees are sent to
    address public treasury;

    /// @notice Record of all the strategies that are allowed to receive assets from the vault
    mapping(address => StrategyData) public strategies;
    /// @notice Ordering that `withdraw` uses to determine which strategies to pull funds from
    address[MAXIMUM_STRATEGIES] public withdrawalQueue;

    /// @notice Fee minted to the treasury and deducted from yield earned every time the vault harvests a strategy
    uint256 public performanceFee;
    /// @notice Flat rate taken from vault yield over a year
    uint256 public managementFee;

    ////////////////////////////////////////////////////////////////
    ///                         MODIFIERS                        ///
    ////////////////////////////////////////////////////////////////

    modifier checkRoles(uint256 roles) {
        _checkRoles(roles);
        _;
    }

    modifier noEmergencyShutdown() {
        assembly ("memory-safe") {
            // if emergencyShutdown == true
            if shr(160, sload(emergencyShutdown.slot)) {
                // throw the `VaultInEmergencyShutdownMode` error
                mstore(0x00, 0x04aca5db)
                revert(0x1c, 0x04)
            }
        }
        _;
    }

    ////////////////////////////////////////////////////////////////
    ///                     CONSTRUCTOR                          ///
    ////////////////////////////////////////////////////////////////
    constructor(IERC20 _underlyingAsset, string memory _name, string memory _symbol)
        ERC20(_name, _symbol, IERC20Metadata(address(_underlyingAsset)).decimals())
    {
        _initializeOwner(msg.sender);
        _grantRoles(msg.sender, ADMIN_ROLE);
        underlyingAsset = _underlyingAsset;
    }

    ////////////////////////////////////////////////////////////////
    ///                    INTERNAL FUNCTIONS                    ///
    ////////////////////////////////////////////////////////////////

    /// @notice Reports a strategy loss, adjusting the corresponding vault and strategy parameters
    /// to minimize trust in the strategy
    /// @param strategy The strategy reporting the loss
    /// @param loss The amount of loss to report
    function _reportLoss(address strategy, uint256 loss) internal {
        // Strategy data
        uint128 strategyTotalDebt;
        uint16 strategyDebtRatio;

        // Vault data
        uint256 totalDebt_;
        uint256 debtRatio_;

        // Slot data
        uint256 strategiesSlot;
        uint256 slot0Content;
        uint256 slot2Content;

        assembly ("memory-safe") {
            // Get strategies slot
            mstore(0x00, strategy)
            mstore(0x20, strategies.slot)
            strategiesSlot := keccak256(0x00, 0x40)
            // Obtain strategy slot 0 data
            slot0Content := sload(strategiesSlot)
            // Obtain strategy slot 2 data
            slot2Content := sload(add(strategiesSlot, 2))

            // Cache strategy data
            strategyDebtRatio := shr(240, shl(240, slot0Content))
            strategyTotalDebt := shr(128, shl(128, slot2Content))

            // Ensure loss reported is not greater than strategy total debt
            // if loss > strategyData.strategyTotalDebt
            if gt(loss, strategyTotalDebt) {
                // throw the `LossGreaterThanStrategyTotalDebt` error
                mstore(0x00, 0xd5436ad8)
                revert(0x1c, 0x04)
            }

            // Obtain vault debtRatio
            debtRatio_ := sload(debtRatio.slot)
            // Obtain vault totalDebt
            totalDebt_ := sload(totalDebt.slot)
        }

        // Reduce trust in this strategy by the amount of loss, lowering the corresponding strategy debt ratio
        uint256 ratioChange = Math.min((loss * debtRatio_) / totalDebt_, strategyDebtRatio);

        assembly {
            // Overflow checks
            if gt(ratioChange, debtRatio_) {
                // throw `Overflwow` error
                revert(0, 0)
            }
            if gt(loss, totalDebt_) {
                // throw `Overflow` error
                revert(0, 0)
            }
            if gt(ratioChange, strategyDebtRatio) {
                // throw `Overflow` error
                revert(0, 0)
            }

            // Update vault data
            // debtRatio -= ratioChange;
            // totalDebt -= loss;
            sstore(debtRatio.slot, sub(debtRatio_, ratioChange)) // debtRatio -= ratioChange
            sstore(totalDebt.slot, sub(totalDebt_, loss)) // totalDebt -= loss

            // Update strategy debt ratio
            // strategies[strategy].strategyDebtRatio -= ratioChange
            sstore(
                strategiesSlot,
                or(
                    shr(240, shl(240, sub(strategyDebtRatio, ratioChange))), // Compute strategies[strategy].strategyDebtRatio - ratioChange
                    shl(16, shr(16, slot0Content)) // Obtain previous slot data, removing `strategyDebtRatio`
                )
            )

            // Adjust final strategy parameters by the loss
            let strategyTotalLoss := shr(128, slot2Content)
            // strategyTotalLoss += loss
            strategyTotalLoss := add(strategyTotalLoss, loss)

            if lt(strategyTotalLoss, loss) {
                // throw `Overflow` error
                revert(0, 0)
            }

            // Pack strategyTotalLoss and strategyTotalDebt into slot2Content
            slot2Content :=
                or(
                    shl(128, strategyTotalLoss),
                    shr(128, shl(128, sub(strategyTotalDebt, loss))) // Compute strategies[strategy].strategyTotalDebt -= loss;
                )

            // Update strategy total loss and total debt, store in slot 2
            sstore(add(strategiesSlot, 2), slot2Content)
        }
    }

    /// @notice Issues new shares to cover performance, management and strategist fees
    /// @param strategy The strategy reporting the gain
    /// @param gain The amount of gain to extract fees from
    /// @return the total fees (performance + management + strategist) extracted from the gain
    function _assessFees(address strategy, uint256 gain) internal returns (uint256) {
        bool success;
        uint256 slot0Content;
        assembly ("memory-safe") {
            // Get strategies[strategy] slot
            mstore(0x00, strategy)
            mstore(0x20, strategies.slot)
            // Get strategies[strategy] data
            slot0Content := sload(keccak256(0x00, 0x40))

            // If strategy was just added or no gains were reported, return 0 as fees
            // if (strategyData.strategyActivation == block.timestamp || gain == 0)
            if or(eq(shr(208, shl(176, slot0Content)), timestamp()), eq(gain, 0)) { success := 1 }
        }
        if (success) {
            return 0;
        }

        // Stack variables to cache
        uint256 duration;
        uint256 strategyPerformanceFee;
        uint256 computedManagementFee;
        uint256 computedStrategistFee;
        uint256 computedPerformanceFee;
        uint256 totalFee;

        assembly ("memory-safe") {
            // duration = block.timestamp - strategyData.strategyLastReport;
            duration := sub(timestamp(), shr(208, shl(128, slot0Content)))

            // if duration == 0
            if iszero(duration) {
                // throw the `FeesAlreadyAssesed` error
                mstore(0x00, 0x17de0c6e)
                revert(0x1c, 0x04)
            }

            // Cache strategy performance fee
            strategyPerformanceFee := shr(240, shl(224, slot0Content))

            // Load vault fees
            let managementFee_ := sload(managementFee.slot)
            let performanceFee_ := sload(performanceFee.slot)

            // Overflow check equivalent to require(managementFee_ == 0 || gain <= type(uint256).max / managementFee_)
            if iszero(iszero(mul(managementFee_, gt(gain, div(not(0), managementFee_))))) { revert(0, 0) }

            // Compute vault management fee
            // computedManagementFee = (gain * managementFee) / MAX_BPS
            computedManagementFee := div(mul(gain, managementFee_), MAX_BPS)

            // Overflow check equivalent to require(strategyPerformanceFee == 0 || gain <= type(uint256).max / strategyPerformanceFee)
            if iszero(iszero(mul(strategyPerformanceFee, gt(gain, div(not(0), strategyPerformanceFee))))) {
                revert(0, 0)
            }

            // Compute strategist fee
            // computedStrategistFee = (gain * strategyData.strategyPerformanceFee) / MAX_BPS;
            computedStrategistFee := div(mul(gain, strategyPerformanceFee), MAX_BPS)

            // Overflow check equivalent to require(performanceFee_ == 0 || gain <= type(uint256).max / performanceFee_)
            if iszero(iszero(mul(performanceFee_, gt(gain, div(not(0), performanceFee_))))) { revert(0, 0) }

            // Compute vault performance fee
            // computedPerformanceFee = (gain * performanceFee) / MAX_BPS;
            computedPerformanceFee := div(mul(gain, performanceFee_), MAX_BPS)

            // totalFee = computedManagementFee + computedStrategistFee + computedPerformanceFee
            totalFee := add(add(computedManagementFee, computedStrategistFee), computedPerformanceFee)

            // Ensure total fee is not greater than the gain, set total fee to become the actual gain otherwise
            // if totalFee > gain
            if gt(totalFee, gain) {
                // totalFee = gain
                totalFee := gain
            }
        }

        // Only transfer shares if there are actual shares to transfer
        if (totalFee != 0) {
            // Compute corresponding shares and mint rewards to vault
            uint256 reward = _issueSharesForAmount(address(this), totalFee);

            // Transfer corresponding rewards in shares to strategist
            if (computedStrategistFee != 0) {
                uint256 strategistReward;
                assembly {
                    // Overflow check equivalent to require(reward == 0 || computedStrategistFee <= type(uint256).max / reward)
                    // No need to check for totalFee == 0 since it is checked in the if clause above
                    if iszero(iszero(mul(reward, gt(computedStrategistFee, div(not(0), reward))))) { revert(0, 0) }

                    // Compute strategist reward
                    // strategistReward = (computedStrategistFee * reward) / totalFee;
                    strategistReward := div(mul(computedStrategistFee, reward), totalFee)
                }
                // Transfer corresponding reward to strategist
                address(this).safeTransfer(IStrategy(strategy).strategist(), strategistReward);
            }

            // Treasury earns remaining shares (performance fee + management fee + any dust leftover from flooring math above)
            uint256 cachedBalance = balanceOf(address(this));
            if (cachedBalance != 0) {
                address(this).safeTransfer(treasury, cachedBalance);
            }
        }

        assembly ("memory-safe") {
            // Emit the `FeesReported` event
            let m := mload(0x40)
            mstore(0x00, computedManagementFee)
            mstore(0x20, computedPerformanceFee)
            mstore(0x40, computedStrategistFee)
            mstore(0x60, duration)
            log1(0x00, 0x80, _FEES_REPORTED_EVENT_SIGNATURE)
            mstore(0x40, m)
            mstore(0x60, 0)
        }

        return totalFee;
    }

    /// @notice Amount of tokens in Vault a Strategy has access to as a credit line.
    /// This will check the Strategy's debt limit, as well as the tokens available in the
    /// Vault, and determine the maximum amount of tokens (if any) the Strategy may draw on
    /// @param strategy The strategy to check
    /// @return The quantity of tokens available for the Strategy to draw on
    function _creditAvailable(address strategy) internal view returns (uint256) {
        if (emergencyShutdown) return 0;

        // Compute necessary data regarding current state of the vault
        uint256 vaultTotalAssets = _totalAssets();
        uint256 vaultDebtLimit = _computeDebtLimit(debtRatio, vaultTotalAssets);
        uint256 vaultTotalDebt = totalDebt;

        // Stack variables to cache
        bool success;
        uint256 slot;
        uint256 slot0Content;
        uint256 strategyTotalDebt;
        uint256 strategyDebtLimit;
        assembly ("memory-safe") {
            // Compute slot of strategies[strategy]
            mstore(0x00, strategy)
            mstore(0x20, strategies.slot)
            slot := keccak256(0x00, 0x40)
            // Load strategies[strategy].strategyTotalDebt
            strategyTotalDebt := shr(128, shl(128, sload(add(slot, 2))))

            // Load slot 0 content
            slot0Content := sload(slot)

            // Extract strategies[strategy].strategyDebtRatio
            let strategyDebtRatio := shr(240, shl(240, slot0Content))

            // Overflow check equivalent to require(vaultTotalAssets == 0 || strategyDebtRatio <= type(uint256).max / vaultTotalAssets)
            if iszero(iszero(mul(vaultTotalAssets, gt(strategyDebtRatio, div(not(0), vaultTotalAssets))))) {
                revert(0, 0)
            }

            // Compute necessary data regarding current state of the strategy

            // strategyDebtLimit = (strategies[strategy].strategyDebtRatio * vaultTotalAssets) / MAX_BPS;
            strategyDebtLimit := div(mul(strategyDebtRatio, vaultTotalAssets), MAX_BPS)

            // If strategy current debt is already greater than the configured debt limit for that strategy,
            // or if the vault's current debt is already greater than the configured debt limit for that vault,
            // no credit should be given to the strategy
            // if strategies[strategy].strategyTotalDebt > strategyDebtLimit || vaultTotalDebt > vaultDebtLimit
            if or(gt(strategyTotalDebt, strategyDebtLimit), gt(vaultTotalDebt, vaultDebtLimit)) { success := 1 }
        }
        if (success) return 0;

        // Adjust by the vault debt limit left
        uint256 available;
        unchecked {
            available = Math.min(strategyDebtLimit - strategyTotalDebt, vaultDebtLimit - vaultTotalDebt);
        }

        // Adjust by the idle amount of underlying the vault has
        available = Math.min(available, totalIdle);

        assembly {
            // Adjust by min and max borrow limits per harvest

            // if (available < strategies[strategy].strategyMinDebtPerHarvest) return 0;
            if lt(available, shr(128, shl(128, sload(add(slot, 1))))) { success := 1 }
        }
        if (success) return 0;

        // Obtain strategies[strategy].strategyMaxDebtPerHarvest from the previously loaded slot0Content, this saves one SLOAD
        uint256 strategyMaxDebtPerHarvest;
        assembly {
            strategyMaxDebtPerHarvest := shr(128, slot0Content)
        }
        return Math.min(available, strategyMaxDebtPerHarvest);
    }

    /// @notice Performs the debt limit calculation
    /// @param _debtRatio The debt ratio to use for computation
    /// @param totalAssets The amount of assets
    /// @return debtLimit The limit amount of assets allowed for the strategy, given the current debt ratio and total assets
    function _computeDebtLimit(uint256 _debtRatio, uint256 totalAssets) internal pure returns (uint256 debtLimit) {
        assembly {
            // Overflow check equivalent to require(totalAssets == 0 || _debtRatio <= type(uint256).max / totalAssets)
            if iszero(iszero(mul(totalAssets, gt(_debtRatio, div(not(0), totalAssets))))) { revert(0, 0) }
            // _debtRatio * totalAssets / MAX_BPS
            debtLimit := div(mul(_debtRatio, totalAssets), MAX_BPS)
        }
    }

    /// @notice Determines if `strategy` is past its debt limit and if any tokens should be withdrawn to the Vault
    /// @param strategy The Strategy to check
    /// @return debtOutstanding The quantity of tokens to withdraw
    function _debtOutstanding(address strategy) internal view returns (uint256 debtOutstanding) {
        uint256 strategyTotalDebt;
        uint256 strategyDebtRatio;
        assembly ("memory-safe") {
            // Get strategies[strategy] slot
            mstore(0x00, strategy)
            mstore(0x20, strategies.slot)
            let slot := keccak256(0x00, 0x40)
            // Obtain strategies[strategy].strategyTotalDebt from slot 2
            strategyTotalDebt := shr(128, shl(128, sload(add(slot, 2))))
            // Obtain strategies[strategy].strategyDebtRatio from slot 0
            strategyDebtRatio := shr(240, shl(240, sload(slot)))
        }
        // If debt ratio configured in vault is zero or emergency shutdown, any amount of debt in the strategy should be returned
        if (debtRatio == 0 || emergencyShutdown) return strategyTotalDebt;

        uint256 strategyDebtLimit = _computeDebtLimit(strategyDebtRatio, _totalAssets());

        // There will not be debt outstanding if strategy total debt is smaller or equal to the current debt limit
        if (strategyDebtLimit >= strategyTotalDebt) {
            return 0;
        }
        unchecked {
            debtOutstanding = strategyTotalDebt - strategyDebtLimit;
        }
    }

    /// @notice Reorganize `withdrawalQueue` based on premise that if there is an
    /// empty value between two actual values, then the empty value should be
    /// replaced by the later value.
    /// @dev Relative ordering of non-zero values is maintained.
    function _organizeWithdrawalQueue() internal {
        uint256 offset;
        for (uint256 i; i < MAXIMUM_STRATEGIES;) {
            address strategy = withdrawalQueue[i];
            if (strategy == address(0)) {
                unchecked {
                    ++offset;
                }
            } else if (offset > 0) {
                withdrawalQueue[i - offset] = strategy;
                withdrawalQueue[i] = address(0);
            }

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Revoke a Strategy, setting its debt limit to 0 and preventing any future deposits
    /// @param strategy The strategy to revoke
    /// @param strategy The strategy debt ratio
    function _revokeStrategy(address strategy, uint256 strategyDebtRatio) internal {
        debtRatio -= strategyDebtRatio;
        strategies[strategy].strategyDebtRatio = 0;
        assembly {
            log2(0x00, 0x00, _STRATEGY_REVOKED_EVENT_SIGNATURE, strategy)
        }
    }

    /// @notice Issues `amount` Vault shares to `to`
    /// @dev Shares must be issued prior to taking on new collateral, or calculation will be wrong.
    /// This means that only *trusted* tokens (with no capability for exploitative behavior) can be used
    /// @param to The shares recipient
    /// @param amount The amount considered to compute the shares
    /// @return shares The amount of shares computed from the amount
    function _issueSharesForAmount(address to, uint256 amount) internal returns (uint256 shares) {
        uint256 vaultTotalSupply = totalSupply();

        // By default, 1:1 shares are minted
        shares = amount;

        if (vaultTotalSupply != 0) {
            // Mint amount of tokens based on what the Vault is managing overall
            shares = (amount * vaultTotalSupply) / _freeFunds();
        }

        assembly ("memory-safe") {
            // if shares == 0
            if iszero(shares) {
                // Throw the `InvalidZeroShares` error
                mstore(0x00, 0x5a870a25)
                revert(0x1c, 0x04)
            }
        }

        _mint(to, shares);
    }

    ////////////////////////////////////////////////////////////////
    ///                INTERNAL VIEW FUNCTIONS                   ///
    ////////////////////////////////////////////////////////////////

    /// @notice Calculates the free funds available considering the locked profit
    /// @return The amount of free funds available
    function _freeFunds() internal view returns (uint256) {
        return _totalAssets() - _calculateLockedProfit();
    }

    /// @notice Returns the total quantity of all assets under control of this Vault,
    /// whether they're loaned out to a Strategy, or currently held in the Vault
    /// @return totalAssets The total assets under control of this Vault
    function _totalAssets() internal view returns (uint256 totalAssets) {
        assembly {
            let totalDebt_ := sload(totalDebt.slot)
            totalAssets := add(sload(totalIdle.slot), totalDebt_)

            // Perform overflow check
            if lt(totalAssets, totalDebt_) { revert(0, 0) }
        }
    }

    /// @notice Calculates how much profit is locked and cant be withdrawn
    /// @return calculatedLockedProfit The total assets locked
    function _calculateLockedProfit() internal view returns (uint256 calculatedLockedProfit) {
        assembly {
            // No need to check for underflow, since block.timestamp is always greater or equal than lastReport
            let difference := sub(timestamp(), sload(lastReport.slot)) // difference = block.timestamp - lastReport
            let lockedProfitDegradation_ := sload(lockedProfitDegradation.slot)

            // Overflow check equivalent to require(lockedProfitDegradation_ == 0 || difference <= type(uint256).max / lockedProfitDegradation_)
            if iszero(iszero(mul(lockedProfitDegradation_, gt(difference, div(not(0), lockedProfitDegradation_))))) {
                revert(0, 0)
            }

            // lockedFundsRatio = (block.timestamp - lastReport) * lockedProfitDegradation
            let lockedFundsRatio := mul(difference, lockedProfitDegradation_)

            if lt(lockedFundsRatio, DEGRADATION_COEFFICIENT) {
                let vaultLockedProfit := sload(lockedProfit.slot)
                // Overflow check equivalent to require(vaultLockedProfit == 0 || lockedFundsRatio <= type(uint256).max / vaultLockedProfit)
                if iszero(iszero(mul(vaultLockedProfit, gt(lockedFundsRatio, div(not(0), vaultLockedProfit))))) {
                    revert(0, 0)
                }
                // ((lockedFundsRatio * vaultLockedProfit) / DEGRADATION_COEFFICIENT
                let degradation := div(mul(lockedFundsRatio, vaultLockedProfit), DEGRADATION_COEFFICIENT)
                // Overflow check
                if gt(degradation, vaultLockedProfit) { revert(0, 0) }
                // calculatedLockedProfit = vaultLockedProfit - ((lockedFundsRatio * vaultLockedProfit) / DEGRADATION_COEFFICIENT);
                calculatedLockedProfit := sub(vaultLockedProfit, degradation)
            }
        }
    }

    /// @notice Determines the amount of underlying corresponding to `shares` amount of shares
    /// @dev Measuring quantity of shares to issue is based on the total outstanding debt that this contract
    /// has ("expected value") instead of the total balance sheet (balanceOf) it has ("estimated value"). This has important
    /// security considerations, and is done intentionally. If this value were measured against external systems, it
    /// could be purposely manipulated by an attacker to withdraw more assets than they otherwise should be able
    /// to claim by redeeming their shares.
    /// @param shares The amount of shares to compute the equivalent underlying for
    /// @return shareValue the value of underlying computed given the `shares` amount of shares given as input
    function _shareValue(uint256 shares) internal view returns (uint256 shareValue) {
        uint256 totalSupply_ = totalSupply();
        // Return price = 1:1 if vault is empty
        if (totalSupply_ == 0) return shares;
        uint256 freeFunds = _freeFunds();
        assembly {
            // Overflow check equivalent to require(freeFunds == 0 || shares <= type(uint256).max / freeFunds)
            if iszero(iszero(mul(freeFunds, gt(shares, div(not(0), freeFunds))))) { revert(0, 0) }
            // shares * freeFunds / totalSupply_
            shareValue := div(mul(shares, freeFunds), totalSupply_)
        }
    }

    /// @notice Determines how many shares `amount` of underlying asset would receive
    /// @param amount The amount to compute the equivalent shares for
    /// @return shares the shares computed given the amount
    function _sharesForAmount(uint256 amount) internal view returns (uint256 shares) {
        uint256 freeFunds = _freeFunds();
        assembly {
            //if (freeFunds != 0) return (amount * totalSupply()) / freeFunds;
            if gt(freeFunds, 0) {
                let totalSupply_ := sload(0x05345cdf77eb68f44c) // load data from `_TOTAL_SUPPLY_SLOT`

                // Overflow check equivalent to require(totalSupply_ == 0 || amount <= type(uint256).max / totalSupply_)
                if iszero(iszero(mul(totalSupply_, gt(amount, div(not(0), totalSupply_))))) { revert(0, 0) }
                // amount * totalSupply() / freeFunds
                shares := div(mul(amount, totalSupply_), freeFunds)
            }
        }
    }
}
