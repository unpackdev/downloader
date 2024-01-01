// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "./BaseVault.sol";

/*KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK
KKKKK0OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO0KKKKKKK
KK0dcclllllllllllllllllllllllllllllccccccccccccccccccclx0KKK
KOc,dKNWWWWWWWWWWWWWWWWWWWWWWWWWWWWNNNNNNNNNNNNNNNNNXOl';xKK
Kd'oWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX; ,kK
Ko'xMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNc .dK
Ko'dMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNc .oK
Kd'oWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNc .oK
KO:,xXWWWWWWWWWWWWWWWWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMNc .oK
KKOl,',;;,,,,,,;;,,,,,,,;;cxXMMMMMMMMMMMMMMMMMMMMMMMMMNc .oK
KKKKOoc;;;;;;;;;;;;;;;;;;;,.cXMMMMMMMMMMMMMMMMMMMMMMMMNc .oK
KKKKKKKKKKKKKKKKKKKK00O00K0:,0MMMMMMMMMMMMMMMMMMMMMMMMNc .oK
KKKKKKKKKKKKKKKKKKklcccccld;,0MMMMMMMMMMMMMMMMMMMMMMMMNc .oK
KKKKKKKKKKKKKKKKkl;ckXNXOc. '0MMMMMMMMMMMMMMMMMMMMMMMMNc .oK
KKKKKKKKKKKKKKkc;l0WMMMMMX; .oKNMMMMMMMMMMMMMMMMMMMMMMNc .oK
KKKKKKKKKKKKkc;l0WMMMMMMMWd.  .,lddddddxONMMMMMMMMMMMMNc .oK
KKKKKKKKKKkc;l0WMMMMMMMMMMWOl::;'.  .....:0WMMMMMMMMMMNc .oK
KKKKKKK0xc;o0WMMMMMMMMMMMMMMMMMWNk'.;xkko'lNMMMMMMMMMMNc .oK
KKKKK0x:;oKWMMMMMMMMMMMMMMMMMMMMMWd..lKKk,lNMMMMMMMMMMNc .oK
KKK0x:;oKWMMMMMMMMMMMMMMMMMMMMMMWO,  c0Kk,lNMMMMMMMMMMNc .oK
KKx:;dKWMMMMMMMMMMMMMMMMMMMMMWN0c.  ;kKKk,lNMMMMMMMMMMNc .oK
Kx,:KWMMMMMMMMMMMMMMMMMMMMMW0c,.  'oOKKKk,lNMMMMMMMMMMNc .oK
Ko'xMMMMMMMMMMMMMMMMMMMMMW0c.   'oOKKKKKk,lNMMMMMMMMMMNc .oK
Ko'xMMMMMMMMMMMMMMMMMMMW0c.  ':oOKKKKKKKk,lNMMMMMMMMMMNc .oK
Ko'xMMMMMMMMMMMMMMMMMW0l.  'oOKKKKKKKKKKk,cNMMMMMMMMMMNc .oK
Ko'xMMMMMMMMMMMMMMMW0l.  'oOKKKKKKKKKKKKk,lNMMMMMMMMMMNc .oK
Ko'dWMMMMMMMMMMMMW0l.  'oOKKKKKKKKKKKKKKk,cNMMMMMMMMMMX: .oK
KO:,xXNWWWWWWWWNOl.  'oOKKKKKKKKKKKKKKKK0c,xNMMMMMMMMNd. .dK
KKOl''',,,,,,,,..  'oOKKKKKKKKKKKKKKKKKKKOl,,ccccccc:'  .c0K
KKKKOoc:;;;;;;;;:ldOKKKKKKKKKKKKKKKKKKKKKKKkl;'......',cx0KK
KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0OOOOOOO0KKK*/

/// @title MaxApy Vault Contract
/// @notice A vault contract deploying `underlyingAsset` to strategies that earn yield and report gains/losses to the vault
/// @author Forked and adapted from YVaults (https://github.com/yearn/yearn-vaults/blob/efb47d8a84fcb13ceebd3ceb11b126b323bcc05d/contracts/Vault.vy)
contract MaxApyVault is BaseVault {
    using SafeTransferLib for address;

    ////////////////////////////////////////////////////////////////
    ///                     CONSTRUCTOR                          ///
    ////////////////////////////////////////////////////////////////
    /// @dev Create the Vault
    /// @param _underlyingAsset The vault's underlying asset that will be deposited by users
    /// @param _name The ERC20 token name for the vault's shares token
    /// @param _symbol The ERC20 token symbol for the vault's shares token
    constructor(IERC20 _underlyingAsset, string memory _name, string memory _symbol, address _treasury)
        BaseVault(_underlyingAsset, _name, _symbol)
    {
        performanceFee = 1000; // 10% of reported yield (per Strategy)
        managementFee = 200; // 2% of reported yield (per Strategy)
        depositLimit = type(uint256).max;
        lastReport = block.timestamp;
        lockedProfitDegradation = (DEGRADATION_COEFFICIENT * 46) / 10 ** 6; // 6 hours in blocks
        treasury = _treasury;
    }

    ////////////////////////////////////////////////////////////////
    ///                 DEPOSIT/WITHDRAWAL LOGIC                 ///
    ////////////////////////////////////////////////////////////////

    /// @notice Deposits `amount` of `underlyingAsset`, issuing shares to `recipient`. If the Vault is in Emergency Shutdown,
    /// deposits will not be accepted and this call will fail.
    /// @dev Measuring quantity of shares to issue is based on the total outstanding debt that this contract
    /// has ("expected value") instead of the total balance sheet it has ("estimated value"). This has important
    /// security considerations, and is done intentionally. If this value were measured against external systems, it
    /// could be purposely manipulated by an attacker to withdraw more assets than they otherwise should be able
    /// to claim by redeeming their shares.
    /// @param amount The quantity of tokens to deposit
    /// @param recipient The address to issue the shares in this Vault to
    function deposit(uint256 amount, address recipient) external noEmergencyShutdown nonReentrant returns (uint256) {
        uint256 totalIdle_;
        assembly ("memory-safe") {
            // if recipient == address(0)
            if iszero(shl(96, recipient)) {
                // throw the `InvalidZeroAddress` error
                mstore(0x00, 0xf6b2911f)
                revert(0x1c, 0x04)
            }
            // if amount == 0
            if iszero(amount) {
                // throw the `InvalidZeroAmount` error
                mstore(0x00, 0xdd484e70)
                revert(0x1c, 0x04)
            }

            // Get totalAssets, same as calling _totalAssets() but caching totalIdle
            totalIdle_ := sload(totalIdle.slot)
            let totalAssets_ := add(totalIdle_, sload(totalDebt.slot))
            if lt(totalAssets_, totalIdle_) { revert(0, 0) }

            // check if totalAssets + amount overflows
            let total := add(totalAssets_, amount)
            if lt(total, totalAssets_) { revert(0, 0) }
            // if totalAssets + amount > depositLimit
            if gt(total, sload(depositLimit.slot)) {
                // throw the `VaultDepositLimitExceeded` error
                mstore(0x00, 0x0c11966b)
                revert(0x1c, 0x04)
            }
        }

        /// Issue new shares (needs to be done before taking deposit to be accurate and not modify `_totalAssets()`)
        // Inline _issueSharesForAmount(recipient, amount) saves 50 gas
        uint256 vaultTotalSupply = totalSupply();
        uint256 shares = amount;
        /// By default minting 1:1 shares

        if (vaultTotalSupply != 0) {
            /// Mint amount of tokens based on what the Vault is managing overall
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

        _mint(recipient, shares);

        address(underlyingAsset).safeTransferFrom(msg.sender, address(this), amount);

        assembly ("memory-safe") {
            sstore(totalIdle.slot, add(totalIdle_, amount))
            // Emit the `Deposit` event
            mstore(0x00, shares)
            mstore(0x20, amount)
            log2(0x00, 0x40, _DEPOSIT_EVENT_SIGNATURE, recipient)
        }

        return shares;
    }

    /// @notice Withdraws the calling account's tokens from this Vault, redeeming
    /// amount `shares` for the corresponding amount of tokens
    /// @dev Measuring quantity of shares to issue is based on the total outstanding debt that this contract
    /// has ("expected value") instead of the total balance sheet it has ("estimated value"). This has important
    /// security considerations, and is done intentionally. If this value were measured against external systems, it
    /// could be purposely manipulated by an attacker to withdraw more assets than they otherwise should be able
    /// to claim by redeeming their shares
    /// @param shares How many shares to try and redeem for tokens
    /// @param recipient The address to issue the shares in this Vault to
    /// @param maxLoss The maximum acceptable loss to sustain on withdrawal. Up to loss specified amount of shares may be
    /// burnt to cover losses on withdrawal
    function withdraw(uint256 shares, address recipient, uint256 maxLoss) external nonReentrant returns (uint256) {
        assembly ("memory-safe") {
            // if maxLoss > MAX_BPS
            if gt(maxLoss, MAX_BPS) {
                // throw the `InvalidMaxLoss` error
                mstore(0x00, 0xef374dc7)
                revert(0x1c, 0x04)
            }

            // if shares == 0
            if iszero(shares) {
                // throw the `InvalidZeroShares` error
                mstore(0x00, 0x5a870a25)
                revert(0x1c, 0x04)
            }

            // if (shares == type(uint256).max) shares = balanceOf(msg.sender);
            if eq(shares, not(0)) {
                // compute `balanceOf(msg.sender)` and store it in `shares`
                mstore(0x0c, 0x87a211a2) // `_BALANCE_SLOT_SEED`
                mstore(0x00, caller())
                shares := sload(keccak256(0x0c, 0x20))
            }
        }

        // Cache underlying asset
        IERC20 underlying = underlyingAsset;

        uint256 valueToWithdraw = _shareValue(shares);
        uint256 vaultBalance = totalIdle;

        // Check if value to withdraw exceeds vault balance
        if (valueToWithdraw > vaultBalance) {
            // Vault balance is not enough to cover withdrawal. We need to perform forced withdrawals
            // from strategies until requested value amount is covered.
            // During forced withdrawal, a Strategy may realize a loss, which is reported back to the
            // Vault. This will affect the withdrawer, affecting the amount of tokens they will
            // receive in exchange for their shares.

            uint256 totalLoss;

            // Iterate over strategies
            for (uint256 i; i < MAXIMUM_STRATEGIES;) {
                address strategy = withdrawalQueue[i];

                // Check if we have exhausted the queue
                if (strategy == address(0)) break;

                // Check if the vault balance is finally enough to cover the requested withdrawal
                if (vaultBalance >= valueToWithdraw) break;

                uint256 slotStrategies2;
                // Compute remaining amount to withdraw considering the current balance of the vault
                uint256 amountNeeded;
                assembly ("memory-safe") {
                    // amountNeeded = valueToWithdraw - vaultBalance;
                    amountNeeded := sub(valueToWithdraw, vaultBalance)

                    // cache slot strategies[strategy].strategyTotalDebt
                    mstore(0x00, strategy)
                    mstore(0x20, strategies.slot)
                    slotStrategies2 := add(keccak256(0x00, 0x40), 2)

                    // compute strategies[strategy].strategyTotalDebt
                    let strategyTotalDebt := shr(128, shl(128, sload(slotStrategies2)))

                    // Don't withdraw more than the debt loaned to the strategy so that the strategy can still continue
                    // to work based on the profits it has.

                    // amountNeeded = Math.min(amountNeeded, strategyTotalDebt)
                    amountNeeded :=
                        xor(amountNeeded, mul(xor(amountNeeded, strategyTotalDebt), lt(strategyTotalDebt, amountNeeded)))
                }

                // Try the next strategy if the current strategy has no debt to be withdrawn
                if (amountNeeded == 0) {
                    unchecked {
                        ++i;
                    }
                    continue;
                }

                // Withdraw from strategy. Compute amount withdrawn
                // considering the difference between balances pre/post withdrawal
                uint256 preBalance = underlying.balanceOf(address(this));
                uint256 loss = IStrategy(strategy).withdraw(amountNeeded);

                uint256 withdrawn = underlying.balanceOf(address(this)) - preBalance;

                // Increase cached vault balance to track the newly withdrawn amount
                vaultBalance += withdrawn;

                // If loss has been realised, withdrawer will incur it, affecting to the amount
                // of value they will receive in exchange for their shares
                if (loss != 0) {
                    valueToWithdraw -= loss;
                    totalLoss += loss;
                    _reportLoss(strategy, loss);
                }

                assembly ("memory-safe") {
                    // Reduce debts by the amount withdrawn
                    //totalDebt -= withdrawn;
                    let totalDebt_ := sload(totalDebt.slot)
                    if gt(withdrawn, totalDebt_) { revert(0, 0) }
                    sstore(totalDebt.slot, sub(totalDebt_, withdrawn))

                    // compute strategies[strategy].strategyTotalDebt
                    let slotContent := sload(slotStrategies2)
                    let strategyTotalDebt := sub(shr(128, shl(128, slotContent)), withdrawn)
                    // strategies[strategy].strategyTotalDebt -= uint128(withdrawn);
                    sstore(slotStrategies2, or(shl(128, shr(128, slotContent)), strategyTotalDebt))
                    // Emit the `WithdrawFromStrategy` event
                    mstore(0x00, strategyTotalDebt)
                    mstore(0x20, loss)
                    log2(0x00, 0x40, _WITHDRAW_FROM_STRATEGY_EVENT_SIGNATURE, strategy)
                }

                unchecked {
                    ++i;
                }
            }

            // Update total idle with the actual vault balance that considers the total withdrawn amount
            totalIdle = vaultBalance;

            // We have withdrawn everything possible out of the withdrawal queue but we still don't
            // have enough to fully pay the user back. Adjust the total amount we've freed up through
            // forced withdrawals
            if (valueToWithdraw > vaultBalance) {
                valueToWithdraw = vaultBalance;
                // Burn number of shares that corresponds to what Vault has on-hand,
                // including the losses incurred during withdrawals
                shares = _sharesForAmount(valueToWithdraw + totalLoss);
            }

            assembly ("memory-safe") {
                let sum := add(valueToWithdraw, totalLoss)
                if lt(sum, valueToWithdraw) {
                    // throw the `Overflow` error
                    revert(0, 0)
                }
                // Ensure max loss allowed has not been reached
                // if (totalLoss > (maxLoss * (valueToWithdraw + totalLoss)) / MAX_BPS)
                if gt(totalLoss, div(mul(maxLoss, sum), MAX_BPS)) {
                    // no need to check overflow here maxLoss is capped at MAX_BPS
                    // throw the `MaxLossReached` error
                    mstore(0x00, 0x9ec5941d)
                    revert(0x1c, 0x04)
                }
            }
        }

        // Burn shares
        _burn(msg.sender, shares);

        // Reduce value withdrawn from vault total idle
        totalIdle -= valueToWithdraw;

        // Transfer underlying to `recipient`
        address(underlying).safeTransfer(recipient, valueToWithdraw);

        assembly ("memory-safe") {
            // Emit the `Withdraw` event
            mstore(0x00, shares)
            mstore(0x20, valueToWithdraw)
            log2(0x00, 0x40, _WITHDRAW_EVENT_SIGNATURE, recipient)
        }

        return valueToWithdraw;
    }

    ////////////////////////////////////////////////////////////////
    ///                      REPORT LOGIC                        ///
    ////////////////////////////////////////////////////////////////

    /// @notice  Reports the amount of assets the calling Strategy has free (usually in terms of ROI).
    /// The performance fee is determined here, off of the strategy's profits (if any), and sent to governance.
    /// The strategist's fee is also determined here (off of profits), to be handled according to the strategist on the next harvest.
    /// @dev For approved strategies, this is the most efficient behavior. The Strategy reports back what it has free, then
    /// Vault "decides" whether to take some back or give it more.
    /// Note that the most it can take is `gain + debtPayment`, and the most it can give is all of the
    /// remaining reserves. Anything outside of those bounds is abnormal behavior
    /// @param gain Amount Strategy has realized as a gain on its investment since its last report, and is free
    /// to be given back to Vault as earnings
    /// @param loss Amount Strategy has realized as a loss on its investment since its last report, and should be
    /// accounted for on the Vault's balance sheet. The loss will reduce the debtRatio for the strategy and vault.
    /// The next time the strategy will harvest, it will pay back the debt in an attempt to adjust to the new debt limit.
    /// @param debtPayment Amount Strategy has made available to cover outstanding debt
    /// @return debt Amount of debt outstanding (if totalDebt > debtLimit or emergency shutdown).
    function report(uint128 gain, uint128 loss, uint128 debtPayment)
        external
        checkRoles(STRATEGY_ROLE)
        returns (uint256)
    {
        // Cache underlying asset
        IERC20 underlying = underlyingAsset;
        // Cache strategy balance
        uint256 senderBalance = underlying.balanceOf(msg.sender);

        assembly ("memory-safe") {
            // Ensure strategy reporting actually has enough funds to cover `gain` and `debtPayment`
            let sum := add(gain, debtPayment)
            if lt(sum, gain) {
                // throw the `Overflow` error
                revert(0, 0)
            }
            // if (underlying.balanceOf(msg.sender) < gain + debtPayment)
            if lt(senderBalance, sum) {
                // throw the `InvalidReportedGainAndDebtPayment` error
                mstore(0x00, 0x746feeec)
                revert(0x1c, 0x04)
            }
        }

        // If strategy suffered a loss, report it
        if (loss > 0) {
            _reportLoss(msg.sender, loss);
        }

        // Assess both management fee and performance fee, and issue both as shares of the vault
        uint256 totalFees = _assessFees(msg.sender, gain);

        // Set gain returns as realized gains for the vault
        strategies[msg.sender].strategyTotalGain += gain;

        // Compute the line of credit the Vault is able to offer the Strategy (if any)
        uint256 credit = _creditAvailable(msg.sender);

        // Compute excess of debt the Strategy wants to transfer back to the Vault (if any)
        uint256 debt = _debtOutstanding(msg.sender);

        // Adjust excess of reported debt payment by the debt outstanding computed
        debtPayment = uint128(Math.min(uint256(debtPayment), debt));

        if (debtPayment != 0) {
            strategies[msg.sender].strategyTotalDebt -= debtPayment;
            totalDebt -= debtPayment;
            debt -= debtPayment;
        }

        // Update the actual debt based on the full credit we are extending to the Strategy
        if (credit != 0) {
            strategies[msg.sender].strategyTotalDebt += uint128(credit);
            totalDebt += credit;
        }

        // Give/take corresponding amount to/from Strategy, based on the difference between the reported gains
        // and the debt needed to be paid off (if any)
        uint256 totalReportedAmount = gain + debtPayment;

        unchecked {
            if (credit > totalReportedAmount) {
                // Credit is greater than the amount reported by the strategy, send funds **to** strategy
                totalIdle -= (credit - totalReportedAmount);
                address(underlying).safeTransfer(msg.sender, credit - totalReportedAmount);
            } else if (totalReportedAmount > credit) {
                // Amount reported by the strategy is greater than the credit, take funds **from** strategy
                totalIdle += (totalReportedAmount - credit);
                address(underlying).safeTransferFrom(msg.sender, address(this), totalReportedAmount - credit);
            }

            // else don't do anything (credit and reported amounts are balanced, hence no transfers need to be executed)
        }

        // Profit is locked and gradually released per block
        uint256 lockedProfitBeforeLoss = _calculateLockedProfit() + gain - totalFees;

        if (lockedProfitBeforeLoss > 0) {
            lockedProfit = lockedProfitBeforeLoss - loss;
        } else {
            lockedProfit = 0;
        }

        // Update reporting time
        strategies[msg.sender].strategyLastReport = uint48(block.timestamp);
        lastReport = block.timestamp;

        emit StrategyReported(
            msg.sender,
            gain,
            loss,
            debtPayment,
            strategies[msg.sender].strategyTotalGain,
            strategies[msg.sender].strategyTotalLoss,
            strategies[msg.sender].strategyTotalDebt,
            credit,
            strategies[msg.sender].strategyDebtRatio
        );

        if (strategies[msg.sender].strategyDebtRatio == 0 || emergencyShutdown) {
            // Take every last penny the Strategy has (Emergency Exit/revokeStrategy)
            return IStrategy(msg.sender).estimatedTotalAssets();
        }

        // Otherwise, just return what we have as debt outstanding
        return debt;
    }

    ////////////////////////////////////////////////////////////////
    ///                STRATEGIES CONFIGURATION                  ///
    ////////////////////////////////////////////////////////////////

    /// @notice Adds a new strategy
    /// @dev The Strategy will be appended to `withdrawalQueue`, and `_organizeWithdrawalQueue` will reorganize the queue order
    /// @param newStrategy The new strategy to add
    /// @param strategyDebtRatio The percentage of the total assets in the vault that the `newStrategy` has access to
    /// @param strategyMaxDebtPerHarvest Lower limit on the increase of debt since last harvest
    /// @param strategyMinDebtPerHarvest Upper limit on the increase of debt since last harvest
    /// @param strategyPerformanceFee The fee the strategist will receive based on this Vault's performance
    function addStrategy(
        address newStrategy,
        uint256 strategyDebtRatio,
        uint256 strategyMaxDebtPerHarvest,
        uint256 strategyMinDebtPerHarvest,
        uint256 strategyPerformanceFee
    ) external checkRoles(ADMIN_ROLE) noEmergencyShutdown {
        uint256 slot; // Slot where strategies[newStrategy] slot will be stored

        assembly ("memory-safe") {
            // General checks

            // if (withdrawalQueue[MAXIMUM_STRATEGIES - 1] != address(0))
            if sload(add(withdrawalQueue.slot, sub(MAXIMUM_STRATEGIES, 1))) {
                // throw `QueueIsFull()` error
                mstore(0x00, 0xa3d0cff3)
                revert(0x1c, 0x04)
            }

            // Strategy checks
            // if (newStrategy == address(0))
            if iszero(newStrategy) {
                // throw `InvalidZeroAddress()` error
                mstore(0x00, 0xf6b2911f)
                revert(0x1c, 0x04)
            }

            // Compute strategies[newStrategy] slot
            mstore(0x00, newStrategy)
            mstore(0x20, strategies.slot)
            slot := keccak256(0x00, 0x40)

            // if (strategies[newStrategy].strategyActivation != 0)
            if shr(208, shl(176, sload(slot))) {
                // throw `StrategyAlreadyActive()` error
                mstore(0x00, 0xc976754d)
                revert(0x1c, 0x04)
            }
        }
        if (IStrategy(newStrategy).vault() != address(this)) {
            assembly ("memory-safe") {
                // throw `InvalidStrategyVault()` error
                mstore(0x00, 0xac4e0773)
                revert(0x1c, 0x04)
            }
        }
        if (IStrategy(newStrategy).underlyingAsset() != address(underlyingAsset)) {
            assembly ("memory-safe") {
                // throw `InvalidStrategyUnderlying()` error
                mstore(0x00, 0xf083d3f1)
                revert(0x1c, 0x04)
            }
        }

        if (IStrategy(newStrategy).strategist() == address(0)) {
            assembly ("memory-safe") {
                // throw `StrategyMustHaveStrategist()` error
                mstore(0x00, 0xeb8bf8b6)
                revert(0x1c, 0x04)
            }
        }

        uint256 debtRatio_;
        assembly ("memory-safe") {
            debtRatio_ := sload(debtRatio.slot)
            // Compute debtRatio + strategyDebtRatio
            let sum := add(debtRatio_, strategyDebtRatio)
            if lt(sum, strategyDebtRatio) {
                // throw the `Overflow` error
                revert(0, 0)
            }

            // if (debtRatio + strategyDebtRatio > MAX_BPS)
            if gt(sum, MAX_BPS) {
                // throw the `InvalidDebtRatio` error
                mstore(0x00, 0x79facb0d)
                revert(0x1c, 0x04)
            }

            // if (strategyMinDebtPerHarvest > strategyMaxDebtPerHarvest)
            if gt(strategyMinDebtPerHarvest, strategyMaxDebtPerHarvest) {
                // throw the `InvalidMinDebtPerHarvest` error
                mstore(0x00, 0x5f3bd953)
                revert(0x1c, 0x04)
            }

            // if (strategyPerformanceFee > 5000)
            if gt(strategyPerformanceFee, 5000) {
                // throw the `InvalidPerformanceFee` error
                mstore(0x00, 0xf14508d0)
                revert(0x1c, 0x04)
            }

            // Add strategy to strategies mapping
            // Strategy struct
            // StrategyData({
            //     strategyPerformanceFee: uint16(strategyPerformanceFee),
            //     strategyDebtRatio: uint16(strategyDebtRatio),
            //     strategyActivation: uint48(block.timestamp),
            //     strategyLastReport: uint48(block.timestamp),
            //     strategyMaxDebtPerHarvest: uint128(strategyMaxDebtPerHarvest),
            //     strategyMinDebtPerHarvest: uint128(strategyMinDebtPerHarvest),
            //     strategyTotalDebt: 0,
            //     strategyTotalGain: 0,
            //     strategyTotalLoss: 0
            // });

            // Using yul saves 5k gas, bitmasks are used to create the `StrategyData` struct above.
            // Slot 0 and slot 1 will be updated. Slot 2 is not updated since it stores `strategyTotalDebt`
            // and `strategyTotalLoss`, which will remain with a value of 0 upon strategy addition.

            // Store data for slot 0 in strategies[newStrategy]
            sstore(
                slot,
                or(
                    shl(128, strategyMaxDebtPerHarvest),
                    or(
                        shl(80, and(0xffffffffffff, timestamp())), // Set `strategyLastReport` to `block.timestamp`
                        or(
                            shl(32, and(0xffffffffffff, timestamp())), // Set `strategyActivation` to `block.timestamp`
                            or(shl(16, and(0xffff, strategyPerformanceFee)), and(0xffff, strategyDebtRatio))
                        )
                    )
                )
            )

            // Store data for slot 1 in strategies[newStrategy]
            sstore(add(slot, 1), shr(128, shl(128, strategyMinDebtPerHarvest)))
        }

        // Grant `STRATEGY_ROLE` to strategy
        _grantRoles(newStrategy, STRATEGY_ROLE);

        assembly {
            // Update vault parameters
            // debtRatio += strategyDebtRatio;
            sstore(debtRatio.slot, add(debtRatio_, strategyDebtRatio))
            // Add strategy to withdrawal queue
            // withdrawalQueue[MAXIMUM_STRATEGIES - 1] = newStrategy;
            sstore(add(withdrawalQueue.slot, sub(MAXIMUM_STRATEGIES, 1)), newStrategy)
        }

        _organizeWithdrawalQueue();

        assembly ("memory-safe") {
            // Emit the `StrategyAdded` event
            mstore(0x00, strategyDebtRatio)
            mstore(0x20, strategyMaxDebtPerHarvest)
            mstore(0x40, strategyMinDebtPerHarvest)
            mstore(0x60, strategyPerformanceFee)
            log2(0x00, 0x80, _STRATEGY_ADDED_EVENT_SIGNATURE, newStrategy)
        }
    }

    /// @notice Removes a strategy from the queue
    /// @dev  We don't do this with `revokeStrategy` because it should still be possible to withdraw from the Strategy if it's unwinding.
    /// @param strategy The strategy to remove
    function removeStrategy(address strategy) external checkRoles(ADMIN_ROLE) noEmergencyShutdown {
        address[MAXIMUM_STRATEGIES] memory cachedWithdrawalQueue = withdrawalQueue;
        for (uint256 i; i < MAXIMUM_STRATEGIES;) {
            if (cachedWithdrawalQueue[i] == strategy) {
                // The strategy was found and can be removed
                withdrawalQueue[i] = address(0);

                _removeRoles(strategy, STRATEGY_ROLE);

                // Update withdrawal queue
                _organizeWithdrawalQueue();

                // Emit the `StrategyRemoved` event
                assembly {
                    log2(0x00, 0x00, _STRATEGY_REMOVED_EVENT_SIGNATURE, strategy)
                }
                return;
            }

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Revoke a Strategy, setting its debt limit to 0 and preventing any future deposits
    /// @dev This function should only be used in the scenario where the Strategy is being retired but no migration
    /// of the positions is possible, or in the extreme scenario that the Strategy needs to be put into "Emergency Exit"
    /// mode in order for it to exit as quickly as possible. The latter scenario could be for any reason that is considered
    /// "critical" that the Strategy exits its position as fast as possible, such as a sudden change in market
    /// conditions leading to losses, or an imminent failure in an external dependency.
    /// @param strategy The strategy to revoke
    function revokeStrategy(address strategy) external checkRoles(ADMIN_ROLE) {
        uint256 cachedStrategyDebtRatio = strategies[strategy].strategyDebtRatio; // Saves an SLOAD if strategy is != addr(0)
        assembly ("memory-safe") {
            // if (strategies[strategy].strategyActivation == 0)
            if iszero(cachedStrategyDebtRatio) {
                // throw `StrategyDebtRatioAlreadyZero()` error
                mstore(0x00, 0xe3a1d5ed)
                revert(0x1c, 0x04)
            }
        }
        // Remove `STRATEGY_ROLE` from strategy
        _removeRoles(strategy, STRATEGY_ROLE);

        // Revoke the strategy
        _revokeStrategy(strategy, cachedStrategyDebtRatio);
    }

    /// @notice Updates a given strategy configured data
    /// @param strategy The strategy to change the data to
    /// @param newDebtRatio The new percentage of the total assets in the vault that `strategy` has access to
    /// @param newMaxDebtPerHarvest New lower limit on the increase of debt since last harvest
    /// @param newMinDebtPerHarvest New upper limit on the increase of debt since last harvest
    /// @param newPerformanceFee New fee the strategist will receive based on this Vault's performance
    function updateStrategyData(
        address strategy,
        uint256 newDebtRatio,
        uint256 newMaxDebtPerHarvest,
        uint256 newMinDebtPerHarvest,
        uint256 newPerformanceFee
    ) external checkRoles(ADMIN_ROLE) {
        uint256 slot; // Slot where strategies[strategy] slot will be stored
        uint256 slotContent; // Used to store strategies[strategy] slot content

        assembly ("memory-safe") {
            // Compute strategies[newStrategy] slot
            mstore(0x00, strategy)
            mstore(0x20, strategies.slot)
            slot := keccak256(0x00, 0x40)

            // Load strategies[newStrategy] data into `slotContent`
            slotContent := sload(slot)
            // if (strategyData.strategyActivation == 0)
            if iszero(shr(208, shl(176, slotContent))) {
                // throw `StrategyNotActive()` error
                mstore(0x00, 0xdc974a98)
                revert(0x1c, 0x04)
            }
        }
        if (IStrategy(strategy).emergencyExit() == 2) {
            assembly ("memory-safe") {
                // throw `StrategyInEmergencyExitMode()` error
                mstore(0x00, 0x57c7c24f)
                revert(0x1c, 0x04)
            }
        }
        assembly ("memory-safe") {
            // if (newMinDebtPerHarvest > newMaxDebtPerHarvest)
            if gt(newMinDebtPerHarvest, newMaxDebtPerHarvest) {
                // throw the `InvalidMinDebtPerHarvest` error
                mstore(0x00, 0x5f3bd953)
                revert(0x1c, 0x04)
            }

            // if (strategyPerformanceFee > 5000)
            if gt(newPerformanceFee, 5000) {
                // throw the `InvalidPerformanceFee` error
                mstore(0x00, 0xf14508d0)
                revert(0x1c, 0x04)
            }
        }

        uint256 strategyDebtRatio_;
        assembly {
            // Compute strategies[newStrategy].strategyDebtRatio
            strategyDebtRatio_ := shr(240, shl(240, slotContent))
        }

        uint256 debtRatio_;
        unchecked {
            // Update `debtRatio` storage as well as cache `debtRatio` final value result in `debtRatio_`
            // Underflowing will make maxbps check fail later
            debtRatio_ = debtRatio -= strategyDebtRatio_;
        }

        assembly ("memory-safe") {
            let sum := add(debtRatio_, newDebtRatio)
            if lt(sum, debtRatio_) {
                // throw the `Overflow` error
                revert(0, 0)
            }
            // if (debtRatio_ + newDebtRatio > MAX_BPS)
            if gt(sum, MAX_BPS) {
                // throw the `InvalidDebtRatio` error
                mstore(0x00, 0x79facb0d)
                revert(0x1c, 0x04)
            }
        }

        unchecked {
            // Add new debt ratio to current `debtRatio`
            debtRatio = debtRatio_ + newDebtRatio;
        }

        assembly ("memory-safe") {
            // Update strategies[strategy] with new updated data: debtRatio, maxDebtPerHarvest, minDebtPerHarvest, performanceFee
            // Slot 0 and slot 1 will be updated with the new values. Slot 2 is not updated since it stores `strategyTotalDebt`
            // and `strategyTotalLoss`, which are not updated in `updateStrategyData()`.

            // Store data for slot 0 in strategies[strategy]
            sstore(
                slot,
                or(
                    // Obtain old values in slot
                    and(shl(32, 0xffffffffffffffffffffffff), slotContent), // Extract previously stored `strategyActivation` and `strategyLastReport`
                    // Build new values to store
                    or(
                        shl(128, newMaxDebtPerHarvest),
                        or(shl(16, and(0xffff, newPerformanceFee)), and(0xffff, newDebtRatio))
                    )
                )
            )
            // Store data for slot 1 in strategies[strategy]
            sstore(
                add(slot, 1),
                or(
                    // Obtain old values in slot
                    shl(128, shr(128, sload(add(slot, 1)))), // Extract previously stored `strategyTotalGain`
                    // Build new values to store
                    shr(128, shl(128, newMinDebtPerHarvest))
                )
            )

            // Emit the `StrategyUpdated` event
            mstore(0x00, newDebtRatio)
            mstore(0x20, newMaxDebtPerHarvest)
            mstore(0x40, newMinDebtPerHarvest)
            mstore(0x60, newPerformanceFee)
            log2(0x00, 0x80, _STRATEGY_UPDATED_EVENT_SIGNATURE, strategy)
        }
    }

    ////////////////////////////////////////////////////////////////
    ///                   VAULT CONFIGURATION                    ///
    ////////////////////////////////////////////////////////////////

    /// @notice Updates the withdrawalQueue to match the addresses and order specified by `queue`
    /// @dev There can be fewer strategies than the maximum, as well as fewer than the total number
    /// of strategies active in the vault.
    /// Note This is order sensitive, specify the addresses in the order in which funds should be
    /// withdrawn (so `queue`[0] is the first Strategy withdrawn from, `queue`[1] is the second, etc.),
    /// and add address(0) only when strategies to be added have occupied first queue positions.
    /// This means that the least impactful Strategy (the Strategy that will have its core positions
    /// impacted the least by having funds removed) should be at `queue`[0], then the next least
    /// impactful at `queue`[1], and so on.
    /// @param queue The array of addresses to use as the new withdrawal queue. **This is order sensitive**.
    function setWithdrawalQueue(address[MAXIMUM_STRATEGIES] calldata queue) external checkRoles(ADMIN_ROLE) {
        address prevStrategy;
        // Check queue order is correct
        for (uint256 i; i < MAXIMUM_STRATEGIES;) {
            assembly ("memory-safe") {
                let strategy := calldataload(add(4, mul(i, 0x20)))
                // if (prevStrategy == address(0) && queue[i] != address(0) && i != 0)
                if and(gt(strategy, 0), and(iszero(prevStrategy), gt(i, 0))) {
                    // throw the `InvalidQueueOrder` error
                    mstore(0x00, 0xefb91db4)
                    revert(0x1c, 0x04)
                }

                // Store data necessary to compute strategies[newStrategy] slot
                mstore(0x00, strategy)
                mstore(0x20, strategies.slot)

                // if (strategy != address(0) && strategies[strategy].strategyActivation == 0)
                if and(iszero(shr(208, shl(176, sload(keccak256(0x00, 0x40))))), gt(strategy, 0)) {
                    // throw the `StrategyNotActive` error
                    mstore(0x00, 0xdc974a98)
                    revert(0x1c, 0x04)
                }
                prevStrategy := strategy
            }

            unchecked {
                ++i;
            }
        }
        withdrawalQueue = queue;
        emit WithdrawalQueueUpdated(queue);
    }

    /// @notice Used to change the value of `performanceFee`
    /// @dev Should set this value below the maximum strategist performance fee
    /// @param _performanceFee The new performance fee to use
    function setPerformanceFee(uint256 _performanceFee) external checkRoles(ADMIN_ROLE) {
        assembly ("memory-safe") {
            // if (strategyPerformanceFee > 5000)
            if gt(_performanceFee, 5000) {
                // throw the `InvalidPerformanceFee` error
                mstore(0x00, 0xf14508d0)
                revert(0x1c, 0x04)
            }
        }
        performanceFee = _performanceFee;
        assembly ("memory-safe") {
            // Emit the `PerformanceFeeUpdated` event
            mstore(0x00, _performanceFee)
            log1(0x00, 0x20, _PERFORMANCE_FEE_UPDATED_EVENT_SIGNATURE)
        }
    }

    /// @notice Used to change the value of `managementFee`
    /// @param _managementFee The new performance fee to use
    function setManagementFee(uint256 _managementFee) external checkRoles(ADMIN_ROLE) {
        assembly ("memory-safe") {
            // if (_managementFee > MAX_BPS)
            if gt(_managementFee, MAX_BPS) {
                // throw the `InvalidManagementFee` error
                mstore(0x00, 0x8e9b51ff)
                revert(0x1c, 0x04)
            }
        }
        managementFee = _managementFee;
        assembly {
            // Emit the `ManagementFeeUpdated` event
            mstore(0x00, _managementFee)
            log1(0x00, 0x20, _MANAGEMENT_FEE_UPDATED_EVENT_SIGNATURE)
        }
    }

    /// @notice Used to change the value of `lockedProfitDegradation`
    /// @param _lockedProfitDegradation The rate of degradation in percent per second scaled to 1e18
    function setLockedProfitDegradation(uint256 _lockedProfitDegradation) external checkRoles(ADMIN_ROLE) {
        assembly ("memory-safe") {
            // if (_lockedProfitDegradation > DEGRADATION_COEFFICIENT)
            if gt(_lockedProfitDegradation, DEGRADATION_COEFFICIENT) {
                // throw the `InvalidLockedProfitDegradation` error
                mstore(0x00, 0xd5fccc67)
                revert(0x1c, 0x04)
            }
        }

        lockedProfitDegradation = _lockedProfitDegradation;

        assembly ("memory-safe") {
            // Emit the `LockedProfitDegradationUpdated` event
            mstore(0x00, _lockedProfitDegradation)
            log1(0x00, 0x20, _LOCKED_PROFIT_DEGRADATION_UPDATED_EVENT_SIGNATURE)
        }
    }

    /// @notice Changes the maximum amount of tokens that can be deposited in this Vault
    /// @dev This is not how much may be deposited by a single depositor,
    /// but the maximum amount that may be deposited across all depositors
    /// @param _depositLimit The new deposit limit to use
    function setDepositLimit(uint256 _depositLimit) external checkRoles(ADMIN_ROLE) {
        depositLimit = _depositLimit;
        assembly ("memory-safe") {
            // Emit the `DepositLimitUpdated` event
            mstore(0x00, _depositLimit)
            log1(0x00, 0x20, _DEPOSIT_LIMIT_UPDATED_EVENT_SIGNATURE)
        }
    }

    /// @notice Activates or deactivates Vault mode where all Strategies go into full withdrawal.
    /// During Emergency Shutdown:
    /// 1. No users may deposit into the Vault (but may withdraw as usual)
    /// 2. No new Strategies may be added
    /// 3. Each Strategy must pay back their debt as quickly as reasonable to minimally affect their position
    /// @param _emergencyShutdown If true, the Vault goes into Emergency Shutdown. If false, the Vault goes back into normal operation
    function setEmergencyShutdown(bool _emergencyShutdown) external checkRoles(EMERGENCY_ADMIN_ROLE) {
        emergencyShutdown = _emergencyShutdown;
        assembly ("memory-safe") {
            // Emit the `EmergencyShutdownUpdated` event
            mstore(0x00, _emergencyShutdown)
            log1(0x00, 0x20, _EMERGENCY_SHUTDOWN_UPDATED_EVENT_SIGNATURE)
        }
    }

    /// @notice Updates the treasury address
    /// @param _treasury The new treasury address
    function setTreasury(address _treasury) external checkRoles(ADMIN_ROLE) {
        treasury = _treasury;
        assembly ("memory-safe") {
            // Emit the `TreasuryUpdated` event
            mstore(0x00, _treasury)
            log1(0x00, 0x20, _TREASURY_UPDATED_EVENT_SIGNATURE)
        }
    }

    ////////////////////////////////////////////////////////////////
    ///                    VIEW FUNCTIONS                        ///
    ////////////////////////////////////////////////////////////////

    /// @notice Returns the total quantity of all assets under control of this Vault,
    /// whether they're loaned out to a Strategy, or currently held in the Vault
    /// @return The total assets under control of this Vault
    function totalAssets() public view returns (uint256) {
        return _totalAssets();
    }

    /// @notice Determines the amount of underlying corresponding to `shares` amount of shares
    /// @dev Measuring quantity of shares to issue is based on the total outstanding debt that this contract
    /// has ("expected value") instead of the total balance sheet (balanceOf) it has ("estimated value"). This has important
    /// security considerations, and is done intentionally. If this value were measured against external systems, it
    /// could be purposely manipulated by an attacker to withdraw more assets than they otherwise should be able
    /// to claim by redeeming their shares.
    /// @param shares The amount of shares to compute the equivalent underlying for
    /// @return the value of underlying computed given the `shares` amount of shares given as input
    function shareValue(uint256 shares) public view returns (uint256) {
        return _shareValue(shares);
    }

    /// @notice Determines how many shares `amount` of underlying asset would receive
    /// @param amount The amount to compute the equivalent shares for
    /// @return shares the shares computed given the amount
    function sharesForAmount(uint256 amount) public view returns (uint256 shares) {
        return _sharesForAmount(amount);
    }

    /// @notice Amount of tokens in Vault a Strategy has access to as a credit line.
    /// This will check the Strategy's debt limit, as well as the tokens available in the
    /// Vault, and determine the maximum amount of tokens (if any) the Strategy may draw on
    /// @param strategy The strategy to check
    /// @return The quantity of tokens available for the Strategy to draw on
    function creditAvailable(address strategy) external view returns (uint256) {
        return _creditAvailable(strategy);
    }

    /// @notice Determines if `strategy` is past its debt limit and if any tokens should be withdrawn to the Vault
    /// @param strategy The Strategy to check
    /// @return The quantity of tokens to withdraw
    function debtOutstanding(address strategy) external view returns (uint256) {
        return _debtOutstanding(strategy);
    }

    /// @notice returns stratetegyTotalDebt, saves gas, no need to return the whole struct
    /// @param strategy The Strategy to check
    /// @return strategyTotalDebt The strategy's total debt
    function getStratetegyTotalDebt(address strategy) external view returns (uint256 strategyTotalDebt) {
        assembly ("memory-safe") {
            // Store data necessary to compute strategies[newStrategy] slot
            mstore(0x00, strategy)
            mstore(0x20, strategies.slot)

            // Obtain strategies[strategy].strategyTotalDebt, stored in struct's slot 2
            strategyTotalDebt := shr(128, shl(128, sload(add(keccak256(0x00, 0x40), 2))))
        }
    }
}
