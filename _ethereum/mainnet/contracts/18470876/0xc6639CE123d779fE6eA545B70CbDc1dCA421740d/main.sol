// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./helpers.sol";

import "./events.sol";

/// @title RebalancerModule
/// @dev Actions are executable by allowed rebalancers only
contract RebalancerModule is Helpers, Events {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /***********************************|
    |              ERRORS               |
    |__________________________________*/
    // Revert if protocol ratio after withdraw is more than max risk ratio.
    error RebalancerModule__VaultUnsafeAfterWithdraw();
    error RebalancerModule__NotValidDepositAmount();
    error RebalancerModule__NotValidWithdrawAmount();
    error RebalancerModule__AggregatedRatioExceeded();
    error RebalancerModule__InvalidSweepAmount();
    error RebalancerModule__NotValidCollectReveuneAmount();
    error RebalancerModule__CollectReveuneAmountIsHigh();

    /***********************************|
    |          REBALANCER CORE          |
    |__________________________________*/
    /// @notice Deposits assets from the Vault to Protocol.
    /// Moves asset from vault
    /// @param protocolId_ Protocol Id in which stETH will be deposited.
    /// @param depositAmount_ stETH amount to deposit.
    /// Note Users can only deposit and withdraw `STETH` from the vault.
    function vaultToProtocolDeposit(uint8 protocolId_, uint256 depositAmount_)
        external
        nonReentrant
        onlyRebalancer
    {
        if (protocolId_ == 4) {
            revert Helpers__EulerDisabled();
        }

        if (depositAmount_ == 0)
            revert RebalancerModule__NotValidDepositAmount();

        if (depositAmount_ == type(uint256).max) {
            depositAmount_ = IERC20Upgradeable(STETH_ADDRESS).balanceOf(
                address(this)
            );
        }

        IERC20Upgradeable(STETH_ADDRESS).safeTransfer(
            address(vaultDSA),
            depositAmount_
        );

        uint256 spellCount_;
        uint256 spellIndex_;

        if (protocolId_ == 1 || protocolId_ == 5) {
            spellCount_ = 1;
        } else {
            spellCount_ = 2;
        }

        string[] memory targets_ = new string[](spellCount_);
        bytes[] memory calldatas_ = new bytes[](spellCount_);

        // Note Depositing max amount from DSA to protocol to deposit any ideal (if remaining) in the vault.

        // Protocol 2, 3, 4, 6 & 7 support wstETH; So converting stETH into wstETH before depositing
        if (
            protocolId_ == 2 
            || protocolId_ == 3 
            || protocolId_ == 4 
            || protocolId_ == 6 
            || protocolId_ == 7
        ) {
            targets_[spellIndex_] = "WSTETH-A";
            calldatas_[spellIndex_] = abi.encodeWithSignature(
                "deposit(uint256,uint256,uint256)",
                type(uint256).max,
                0,
                0
            );

            spellIndex_++;
        }

        if (protocolId_ == 1) {
            targets_[spellIndex_] = "AAVE-V2-A";
            calldatas_[spellIndex_] = abi.encodeWithSignature(
                "deposit(address,uint256,uint256,uint256)",
                STETH_ADDRESS,
                type(uint256).max,
                0,
                0
            );
        } else if (protocolId_ == 2) {
            targets_[spellIndex_] = "AAVE-V3-A";
            calldatas_[spellIndex_] = abi.encodeWithSignature(
                "deposit(address,uint256,uint256,uint256)",
                WSTETH_ADDRESS,
                type(uint256).max,
                0,
                0
            );
        } else if (protocolId_ == 3) {
            targets_[spellIndex_] = "COMPOUND-V3-A";
            calldatas_[spellIndex_] = abi.encodeWithSignature(
                "deposit(address,address,uint256,uint256,uint256)",
                COMP_ETH_MARKET_ADDRESS,
                WSTETH_ADDRESS,
                type(uint256).max,
                0,
                0
            );
        } else if (protocolId_ == 4) {
            targets_[spellIndex_] = "EULER-A";
            calldatas_[spellIndex_] = abi.encodeWithSignature(
                "deposit(uint256,address,uint256,bool,uint256,uint256)",
                0,
                WSTETH_ADDRESS,
                type(uint256).max,
                true,
                0,
                0
            );
        } else if (protocolId_ == 5) {
            targets_[spellIndex_] = "MORPHO-AAVE-V2-A";
            calldatas_[spellIndex_] = abi.encodeWithSignature(
                "deposit(address,address,uint256,uint256,uint256)",
                STETH_ADDRESS,
                A_STETH_ADDRESS,
                type(uint256).max,
                0,
                0
            );
        } else if (protocolId_ == 6) {
            targets_[spellIndex_] = "MORPHO-AAVE-V3-A";
            calldatas_[spellIndex_] = abi.encodeWithSignature(
                "depositCollateral(address,uint256,uint256,uint256)",
                WSTETH_ADDRESS,
                type(uint256).max,
                0,
                0
            );
        } else if (protocolId_ == 7) {
            targets_[spellIndex_] = "SPARK-A";
            calldatas_[spellIndex_] = abi.encodeWithSignature(
                "deposit(address,uint256,uint256,uint256)",
                WSTETH_ADDRESS,
                type(uint256).max,
                0,
                0
            );
        }

        vaultDSA.cast(targets_, calldatas_, address(this));

        /// Note: No need for checking end ratio here since deposit will always make the ratio less.

        emit LogVaultToProtocolDeposit(protocolId_, depositAmount_);
    }

    /// @notice Fills vault with `STETH` withdrawal availability.
    /// @param protocolId_ Protocol id from which amount will be withdrawn.
    /// @param withdrawAmount_ stEth amount to withdraw based on the protocol.
    /// Note Only keeping STETH in the withdrawal to avoid complexity and follow ERC4626 standards properly.
    function fillVaultAvailability(uint8 protocolId_, uint256 withdrawAmount_)
        external
        nonReentrant
        onlyRebalancer
    {
        if (protocolId_ == 4) {
            revert Helpers__EulerDisabled();
        }

        if (withdrawAmount_ == 0)
            revert RebalancerModule__NotValidWithdrawAmount();

        uint256 spellIndex_;
        uint256 spellCount_;
        uint256 wstethPerSteth_ = WSTETH_CONTRACT.tokensPerStEth();
        uint256 internalWithdrawAmount_;

        if (protocolId_ == 1 || protocolId_ == 5) {
            spellCount_ = 2;
            internalWithdrawAmount_ = withdrawAmount_;
        } else {
            spellCount_ = 3;

            // Note withdraw amount will always be in stETH.
            // Converting stETH to wstETH for wstETH based protocols.
            internalWithdrawAmount_ =
                (withdrawAmount_ * wstethPerSteth_) /
                1e18;
        }

        string[] memory targets_ = new string[](spellCount_);
        bytes[] memory calldatas_ = new bytes[](spellCount_);

        if (protocolId_ == 1) {
            // stETH based protocol
            targets_[spellIndex_] = "AAVE-V2-A";
            calldatas_[spellIndex_] = abi.encodeWithSignature(
                "withdraw(address,uint256,uint256,uint256)",
                STETH_ADDRESS,
                internalWithdrawAmount_,
                0,
                0
            );
        } else if (protocolId_ == 2) {
            // wstETH based protocol
            targets_[spellIndex_] = "AAVE-V3-A";
            calldatas_[spellIndex_] = abi.encodeWithSignature(
                "withdraw(address,uint256,uint256,uint256)",
                WSTETH_ADDRESS,
                internalWithdrawAmount_,
                0,
                0
            );
        } else if (protocolId_ == 3) {
            // wstETH based protocol
            targets_[spellIndex_] = "COMPOUND-V3-A";
            calldatas_[spellIndex_] = abi.encodeWithSignature(
                "withdraw(address,address,uint256,uint256,uint256)",
                COMP_ETH_MARKET_ADDRESS,
                WSTETH_ADDRESS,
                internalWithdrawAmount_,
                0,
                0
            );
        } else if (protocolId_ == 4) {
            // wstETH based protocol
            targets_[spellIndex_] = "EULER-A";
            calldatas_[spellIndex_] = abi.encodeWithSignature(
                "withdraw(uint256,address,uint256,uint256,uint256)",
                0,
                WSTETH_ADDRESS,
                internalWithdrawAmount_,
                0,
                0
            );
        } else if (protocolId_ == 5) {
            // stETH based protocol
            targets_[spellIndex_] = "MORPHO-AAVE-V2-A";
            calldatas_[spellIndex_] = abi.encodeWithSignature(
                "withdraw(address,address,uint256,uint256,uint256)",
                STETH_ADDRESS,
                A_STETH_ADDRESS,
                internalWithdrawAmount_,
                0,
                0
            );
        } else if (protocolId_ == 6) {
            // wstETH based protocol
            targets_[spellIndex_] = "MORPHO-AAVE-V3-A";
            calldatas_[spellIndex_] = abi.encodeWithSignature(
                "withdrawCollateral(address,uint256,uint256,uint256)",
                WSTETH_ADDRESS,
                internalWithdrawAmount_,
                0,
                0
            );
        } else if (protocolId_ == 7) {
            // wstETH based protocol
            targets_[spellIndex_] = "SPARK-A";
            calldatas_[spellIndex_] = abi.encodeWithSignature(
                "withdraw(address,uint256,uint256,uint256)",
                WSTETH_ADDRESS,
                internalWithdrawAmount_,
                0,
                0
            );
        }

        spellIndex_++;

        // Protocol 2,3 & 4 support wstETH; So converting wstETH into stETH before withdrawing.
        if (protocolId_ == 2 || protocolId_ == 3 || protocolId_ == 4 || protocolId_ == 6 || protocolId_ == 7) {
            targets_[spellIndex_] = "WSTETH-A";
            calldatas_[spellIndex_] = abi.encodeWithSignature(
                "withdraw(uint256,uint256,uint256)",
                type(uint256).max,
                0,
                0
            );

            spellIndex_++;
        }

        // Using max amount to withdraw stETH from DSA to vault to withdraw any ideal stETH from DSA.
        targets_[spellIndex_] = "BASIC-A";
        calldatas_[spellIndex_] = abi.encodeWithSignature(
            "withdraw(address,uint256,address,uint256,uint256)",
            STETH_ADDRESS,
            type(uint256).max,
            address(this),
            0,
            0
        );

        vaultDSA.cast(targets_, calldatas_, address(this));

        uint256 protocolRatio_ = getProtocolRatio(protocolId_);

        if (protocolRatio_ > maxRiskRatio[protocolId_])
            revert RebalancerModule__VaultUnsafeAfterWithdraw();

        emit LogFillVaultAvailability(protocolId_, withdrawAmount_);
    }

    function sweepWethToSteth() public nonReentrant onlyRebalancer {
        uint256 dsaWethBal_ = IERC20Upgradeable(WETH_ADDRESS).balanceOf(
            address(vaultDSA)
        );

        if (dsaWethBal_ < 1e6) {
            revert RebalancerModule__InvalidSweepAmount();
        }

        string[] memory targets_ = new string[](2); // wETH => eth; eth => stETH
        bytes[] memory calldatas_ = new bytes[](2);
        uint256 withdrawId_ = 113734774;

        // Withdraw ETH from wETH.
        targets_[0] = "WETH-A";
        calldatas_[0] = abi.encodeWithSignature(
            "withdraw(uint256,uint256,uint256)",
            type(uint256).max,
            0,
            withdrawId_
        );

        // convert ETH into stETH
        targets_[1] = "LIDO-STETH-A";
        calldatas_[1] = abi.encodeWithSignature(
            "deposit(uint256,uint256,uint256)",
            dsaWethBal_,
            withdrawId_,
            0
        );

        vaultDSA.cast(targets_, calldatas_, address(this));

        emit LogWethSweep(dsaWethBal_);
    }

    function sweepEthToSteth() public nonReentrant onlyRebalancer {
        uint256 dsaEthBal_ = address(vaultDSA).balance;

        if (dsaEthBal_ < 1e6) {
            revert RebalancerModule__InvalidSweepAmount();
        }

        string[] memory targets_ = new string[](1); // ETH => stETH
        bytes[] memory calldatas_ = new bytes[](1);

        // convert ETH into stETH
        targets_[0] = "LIDO-STETH-A";
        calldatas_[0] = abi.encodeWithSignature(
            "deposit(uint256,uint256,uint256)",
            dsaEthBal_,
            0,
            0
        );

        vaultDSA.cast(targets_, calldatas_, address(this));

        emit LogEthSweep(dsaEthBal_);
    }

    /// @notice Open function to collect the revenue stored.
    /// @param amount_ Amount of `STETH` revenue to collect.
    /// Note The amount will be transferred to the `treasury` address stored.
    function collectRevenue(uint256 amount_)
        external
        nonReentrant
        onlyRebalancer
    {
        if (amount_ == type(uint256).max) amount_ = revenue;

        if (amount_ == 0)
            revert RebalancerModule__NotValidCollectReveuneAmount();
        if (amount_ > revenue)
            revert RebalancerModule__CollectReveuneAmountIsHigh();

        /// @dev Deducting the amount from revenue before transfering so that
        /// if any reentrancy happens, amount is deducted first and then the
        /// assets are transferred, which is a valid state.
        revenue -= amount_;

        /// @dev transferring to `treasury` address stored.
        IERC20Upgradeable(STETH_ADDRESS).safeTransfer(
            treasury,
            amount_
        );

        emit LogCollectRevenue(amount_, treasury);
    }

    /// @notice Sets the exchange price and revenue based on current net assets(excluding reveune)
    /// @dev Revenue is only collected if there is a profit
    function updateExchangePrice()
        public
        nonReentrant
        onlyRebalancer
        returns (uint256 newExchangePrice_, uint256 newRevenue_)
    {
        uint256 iTokenSupply_ = totalSupply();

        //  If iToken supply doesn't exist yet, the exchange rate will be 1e18 or last updated exchangePrice.
        if (iTokenSupply_ == 0) {
            return (exchangePrice, revenue);
        }

        // Based on old net assets.
        uint256 oldExchangePrice_ = exchangePrice;

        // Updates the peer-to-peer indexes and pool indexes for stETH and ETH.
        MORPHO_CONTRACT.updateIndexes(A_STETH_ADDRESS);
        MORPHO_CONTRACT.updateIndexes(A_WETH_ADDRESS);

        // Current total net assets (totalAssets - totalDebt - reveune)
        (, , uint256 currentNetAssets_, , ) = getNetAssets();

        // Calculating new exchangePrice based on currentNetAssets(excluding revenue)
        newExchangePrice_ = (currentNetAssets_ * 1e18) / iTokenSupply_;

        // Set the new exchange price in storage. revenueFeePercentage of this profit is revenue.
        // Calculate the revenue only if new exchange price > the last updated revenue exchange price.
        // Note In case the vault experiences a loss, the vault will be
        // recovered first to its old state before collecting any new profits.
        if (newExchangePrice_ > revenueExchangePrice) {
            uint256 newProfit_ = currentNetAssets_ -
                ((revenueExchangePrice * iTokenSupply_) / 1e18); // currentNetAssets_(excluding reveune) - oldNetAssets_(excluding reveune)

            // revenueFeePercentage is scaled by factor 4. 1% = 1e4; 100% = 1e6.
            newRevenue_ = (newProfit_ * revenueFeePercentage) / 1e6;

            // updating revenue on storage
            revenue += newRevenue_;

            // updating exchange price on storage
            exchangePrice =
                ((currentNetAssets_ - newRevenue_) * 1e18) /
                iTokenSupply_;

            revenueExchangePrice = exchangePrice;
        } else {
            // updating exchange price on storage without calculating reveune
            exchangePrice = newExchangePrice_;
        }

        emit LogUpdateExchangePrice(oldExchangePrice_, exchangePrice);
    }
}
