//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title InstaLite.
 * @dev InstaLite Vault 1.
 */

import "./helpers.sol";
import "./Address.sol";

contract AdminModule is Helpers {
    /**
     * @dev Only auth gaurd.
     */
    modifier onlyAuth() {
        require(auth == msg.sender, "only auth");
        _;
    }

    /**
     * @dev Only rebalancer gaurd.
     */
    modifier onlyRebalancer() {
        require(
            isRebalancer[msg.sender] || auth == msg.sender,
            "only rebalancer"
        );
        _;
    }

    /**
     * @dev Update auth.
     * @param auth_ address of new auth.
     */
    function updateAuth(address auth_) external onlyAuth {
        auth = auth_;
        emit updateAuthLog(auth_);
    }

    /**
     * @dev Update rebalancer.
     * @param rebalancer_ address of rebalancer.
     * @param isRebalancer_ true for setting the rebalancer, false for removing.
     */
    function updateRebalancer(address rebalancer_, bool isRebalancer_)
        external
        onlyAuth
    {
        isRebalancer[rebalancer_] = isRebalancer_;
        emit updateRebalancerLog(rebalancer_, isRebalancer_);
    }

    /**
     * @dev Update revenue fee.
     * @param newRevenueFee_ new revenue fee.
     */
    function updateRevenueFee(uint256 newRevenueFee_) external onlyAuth {
        uint256 oldRevenueFee_ = revenueFee;
        revenueFee = newRevenueFee_;
        emit updateRevenueFeeLog(oldRevenueFee_, newRevenueFee_);
    }

    /**
     * @dev Update withdrawal fee.
     * @param newWithdrawalFee_ new withdrawal fee.
     */
    function updateWithdrawalFee(uint256 newWithdrawalFee_) external onlyAuth {
        uint256 oldWithdrawalFee_ = withdrawalFee;
        withdrawalFee = newWithdrawalFee_;
        emit updateWithdrawalFeeLog(oldWithdrawalFee_, newWithdrawalFee_);
    }

    /**
     * @dev Update ratios.
     * @param ratios_ new ratios.
     */
    function updateRatios(uint16[] memory ratios_) external onlyAuth {
        ratios = Ratios(
            ratios_[0],
            ratios_[1],
            ratios_[2],
            uint128(ratios_[3]) * 1e23
        );
        emit updateRatiosLog(
            ratios_[0],
            ratios_[1],
            ratios_[2],
            uint128(ratios_[3]) * 1e23
        );
    }

    /**
     * @dev Change status.
     * @param status_ new status, function to pause all functionality of the contract, status = 2 -> pause, status = 1 -> resume.
     */
    function changeStatus(uint256 status_) external onlyAuth {
        _status = status_;
        emit changeStatusLog(status_);
    }
}

contract CoreHelpers is AdminModule {
    using SafeERC20 for IERC20;

    /**
     * @dev Update storage.
     * @notice Internal function to update storage.
     */
    function updateStorage(uint256 exchangePrice_, uint256 newRevenue_)
        internal
    {
        if (exchangePrice_ > lastRevenueExchangePrice) {
            lastRevenueExchangePrice = exchangePrice_;
            revenue = revenue + newRevenue_;
        }
    }

    /**
     * @dev internal function which handles supplies.
     */
    function supplyInternal(
        address token_,
        uint256 amount_,
        address to_,
        bool isEth_
    ) internal returns (uint256 vtokenAmount_) {
        require(amount_ != 0, "amount cannot be zero");
        (
            uint256 exchangePrice_,
            uint256 newRevenue_
        ) = getCurrentExchangePrice();
        updateStorage(exchangePrice_, newRevenue_);
        if (isEth_) {
            wethCoreContract.deposit{value: amount_}();
        } else {
            if (token_ == stEthAddr) {
                IERC20(token_).safeTransferFrom(
                    msg.sender,
                    address(this),
                    amount_
                );
            } else if (token_ == wethAddr) {
                IERC20(token_).safeTransferFrom(
                    msg.sender,
                    address(this),
                    amount_
                );
            } else {
                revert("wrong-token");
            }
        }
        vtokenAmount_ = (amount_ * 1e18) / exchangePrice_;
        _mint(to_, vtokenAmount_);
        emit supplyLog(token_, amount_, to_);
    }

    /**
     * @dev Withdraw helper.
     */
    function withdrawHelper(uint256 amount_, uint256 limit_)
        internal
        pure
        returns (uint256, uint256)
    {
        uint256 transferAmt_;
        if (limit_ > amount_) {
            transferAmt_ = amount_;
            amount_ = 0;
        } else {
            transferAmt_ = limit_;
            amount_ = amount_ - limit_;
        }
        return (amount_, transferAmt_);
    }

    /**
     * @dev Withdraw final.
     */
    function withdrawFinal(uint256 amount_)
        public
        view
        returns (uint256[] memory transferAmts_)
    {
        require(amount_ > 0, "amount-invalid");

        (
            uint256 netCollateral_,
            uint256 netBorrow_,
            BalVariables memory balances_,
            ,

        ) = netAssets();

        uint256 ratio_ = netCollateral_ > 0
            ? (netBorrow_ * 1e4) / netCollateral_
            : 0;
        require(ratio_ < ratios.maxLimit, "already-risky"); // don't allow any withdrawal if aave position is risky

        require(amount_ < balances_.totalBal, "excess-withdrawal");

        transferAmts_ = new uint256[](4);
        if (balances_.wethVaultBal > 10) {
            (amount_, transferAmts_[0]) = withdrawHelper(
                amount_,
                balances_.wethVaultBal
            );
        }
        if (balances_.wethDsaBal > 10 && amount_ > 0) {
            (amount_, transferAmts_[1]) = withdrawHelper(
                amount_,
                balances_.wethDsaBal
            );
        }
        if (balances_.stethVaultBal > 10 && amount_ > 0) {
            (amount_, transferAmts_[2]) = withdrawHelper(
                amount_,
                balances_.stethVaultBal
            );
        }
        if (balances_.stethDsaBal > 10 && amount_ > 0) {
            (amount_, transferAmts_[3]) = withdrawHelper(
                amount_,
                balances_.stethDsaBal
            );
        }
    }

    /**
     * @dev Internal function to handle withdraws.
     */
    function withdrawTransfers(uint256 amount_, uint256[] memory transferAmts_)
        internal
        returns (uint256 wethAmt_, uint256 stEthAmt_)
    {
        wethAmt_ = transferAmts_[0] + transferAmts_[1];
        stEthAmt_ = transferAmts_[2] + transferAmts_[3];
        uint256 totalTransferAmount_ = wethAmt_ + stEthAmt_;
        require(amount_ == totalTransferAmount_, "transfers-not-valid");
        // batching up spells and withdrawing all the required asset from DSA to vault at once
        uint256 i;
        uint256 j;
        if (transferAmts_[1] > 0 && transferAmts_[3] > 0) {
            i = 2;
        } else if (transferAmts_[3] > 0 || transferAmts_[1] > 0) {
            i = 1;
        } else {
            return (wethAmt_, stEthAmt_);
        }
        string[] memory targets_ = new string[](i);
        bytes[] memory calldata_ = new bytes[](i);
        if (transferAmts_[1] > 0) {
            targets_[j] = "BASIC-A";
            calldata_[j] = abi.encodeWithSignature(
                "withdraw(address,uint256,address,uint256,uint256)",
                wethAddr,
                transferAmts_[1],
                address(this),
                0,
                0
            );
            j++;
        }
        if (transferAmts_[3] > 0) {
            targets_[j] = "BASIC-A";
            calldata_[j] = abi.encodeWithSignature(
                "withdraw(address,uint256,address,uint256,uint256)",
                stEthAddr,
                transferAmts_[3],
                address(this),
                0,
                0
            );
            j++;
        }
        if (i > 0) vaultDsa.cast(targets_, calldata_, address(this));
    }
}

contract InstaVaultImplementation is CoreHelpers {
    using SafeERC20 for IERC20;

    /**
     * @dev Supply Eth.
     * @param to_ address to send vTokens to.
     * @return vtokenAmount_ amount of vTokens sent to the `to_` address passed
     */
    function supplyEth(address to_)
        external
        payable
        nonReentrant
        returns (uint256 vtokenAmount_)
    {
        uint256 amount_ = msg.value;
        vtokenAmount_ = supplyInternal(ethAddr, amount_, to_, true);
    }

    /**
     * @dev User function to supply (WETH or STETH).
     * @param token_ address of token, steth or weth.
     * @param amount_ amount to supply.
     * @param to_ address to send vTokens to.
     * @return vtokenAmount_ amount of vTokens sent to the `to_` address passed
     */
    function supply(
        address token_,
        uint256 amount_,
        address to_
    ) external nonReentrant returns (uint256 vtokenAmount_) {
        vtokenAmount_ = supplyInternal(token_, amount_, to_, false);
    }

    /**
     * @dev User function to withdraw (to get WETH or STETH).
     * @param amount_ amount to withdraw.
     * @param to_ address to send tokens to.
     * @return vtokenAmount_ amount of vTokens burnt from caller
     */
    function withdraw(uint256 amount_, address to_)
        external
        nonReentrant
        returns (uint256 vtokenAmount_)
    {
        require(amount_ != 0, "amount cannot be zero");

        (
            uint256 exchangePrice_,
            uint256 newRevenue_
        ) = getCurrentExchangePrice();
        updateStorage(exchangePrice_, newRevenue_);

        if (amount_ == type(uint256).max) {
            vtokenAmount_ = balanceOf(msg.sender);
            amount_ = (vtokenAmount_ * exchangePrice_) / 1e18;
        } else {
            vtokenAmount_ = (amount_ * 1e18) / exchangePrice_;
        }

        _burn(msg.sender, vtokenAmount_);
        uint256 fee_ = (amount_ * withdrawalFee) / 10000;
        uint256 amountAfterFee_ = amount_ - fee_;

        uint256[] memory transferAmts_ = withdrawFinal(amountAfterFee_);

        (uint256 wethAmt_, uint256 stEthAmt_) = withdrawTransfers(
            amountAfterFee_,
            transferAmts_
        );

        if (wethAmt_ > 0) {
            // withdraw weth and sending ETH to user
            wethCoreContract.withdraw(wethAmt_);
            Address.sendValue(payable(to_), wethAmt_);
        }
        if (stEthAmt_ > 0) stEthContract.safeTransfer(to_, stEthAmt_);

        emit withdrawLog(amount_, to_);
    }

    struct RebalanceOneVariables {
        uint256 stETHBal_;
        string[] targets;
        bytes[] calldatas;
        bool[] checks;
        uint length;
        bool isOk;
        bytes encodedFlashData;
        string[] flashTarget;
        bytes[] flashCalldata;
    }

    /**
     * @dev Rebalancer function to leverage and rebalance the position.
     */
    function rebalanceOne(
        address flashTkn_,
        uint256 flashAmt_,
        uint256 route_,
        address[] memory vaults_, // leverage using other vaults
        uint256[] memory amts_,
        uint256 excessDebt_,
        uint256 paybackDebt_,
        uint256 totalAmountToSwap_,
        uint256 extraWithdraw_,
        uint256 unitAmt_,
        bytes memory oneInchData_
    ) external nonReentrant onlyRebalancer {
        if (excessDebt_ < 1e14) excessDebt_ = 0;
        if (paybackDebt_ < 1e14) paybackDebt_ = 0;
        if (totalAmountToSwap_ < 1e14) totalAmountToSwap_ = 0;
        if (extraWithdraw_ < 1e14) extraWithdraw_ = 0;

        RebalanceOneVariables memory v_;

        v_.length = amts_.length;
        require(vaults_.length == v_.length, "unequal-length");

        require(
            !(excessDebt_ > 0 && paybackDebt_ > 0),
            "cannot-borrow-and-payback-at-once"
        );
        require(
            !(totalAmountToSwap_ > 0 && paybackDebt_ > 0),
            "cannot-swap-and-payback-at-once"
        );
        require(
            !((totalAmountToSwap_ > 0 || v_.length > 0) && excessDebt_ == 0),
            "cannot-swap-and-when-zero-excess-debt"
        );

        BalVariables memory balances_ = getIdealBalances();

        if (balances_.wethVaultBal > 1e14)
            wethContract.safeTransfer(
                address(vaultDsa),
                balances_.wethVaultBal
            );
        if (balances_.stethVaultBal > 1e14)
            stEthContract.safeTransfer(
                address(vaultDsa),
                balances_.stethVaultBal
            );
        v_.stETHBal_ = balances_.stethVaultBal + balances_.stethDsaBal;
        if (v_.stETHBal_ < 1e14) v_.stETHBal_ = 0;

        uint256 i;
        uint256 j;
        if (excessDebt_ > 0) j += 4;
        if (v_.length > 0) j += v_.length;
        if (totalAmountToSwap_ > 0) j += 1;
        if (excessDebt_ > 0 && (totalAmountToSwap_ > 0 || v_.stETHBal_ > 0)) j += 1;
        if (paybackDebt_ > 0) j += 1;
        if (v_.stETHBal_ > 0 && excessDebt_ == 0) j += 1;
        if (extraWithdraw_ > 0) j += 2;
        v_.targets = new string[](j);
        v_.calldatas = new bytes[](j);
        if (excessDebt_ > 0) {
            v_.targets[0] = "AAVE-V2-A";
            v_.calldatas[0] = abi.encodeWithSignature(
                "deposit(address,uint256,uint256,uint256)",
                flashTkn_,
                flashAmt_,
                0,
                0
            );
            v_.targets[1] = "AAVE-V2-A";
            v_.calldatas[1] = abi.encodeWithSignature(
                "borrow(address,uint256,uint256,uint256,uint256)",
                wethAddr,
                excessDebt_,
                2,
                0,
                0
            );
            i = 2;
            // Doing swaps from different vaults using deleverage to reduce other vaults riskiness if needed.
            // It takes WETH from vault and gives astETH at 1:1
            for (uint k = 0; k < v_.length; k++) {
                v_.targets[i] = "LITE-A"; // Instadapp Lite vaults connector
                v_.calldatas[i] = abi.encodeWithSignature(
                    "deleverage(address,uint256,uint256,uint256)",
                    vaults_[k],
                    amts_[k],
                    0,
                    0
                );
                i++;
            }
            if (totalAmountToSwap_ > 0) {
                require(unitAmt_ > (1e18 - 10), "invalid-unit-amt");
                v_.targets[i] = "1INCH-A";
                v_.calldatas[i] = abi.encodeWithSignature(
                    "sell(address,address,uint256,uint256,bytes,uint256)",
                    stEthAddr,
                    wethAddr,
                    totalAmountToSwap_,
                    unitAmt_,
                    oneInchData_,
                    0
                );
                i++;
            }
            if (totalAmountToSwap_ > 0 || v_.stETHBal_ > 0) {
                v_.targets[i] = "AAVE-V2-A";
                v_.calldatas[i] = abi.encodeWithSignature(
                    "deposit(address,uint256,uint256,uint256)",
                    stEthAddr,
                    type(uint256).max,
                    0,
                    0
                );
                i++;
            }
            v_.targets[i] = "AAVE-V2-A";
            v_.calldatas[i] = abi.encodeWithSignature(
                "withdraw(address,uint256,uint256,uint256)",
                flashTkn_,
                flashAmt_,
                0,
                0
            );
            v_.targets[i + 1] = "INSTAPOOL-C";
            v_.calldatas[i + 1] = abi.encodeWithSignature(
                "flashPayback(address,uint256,uint256,uint256)",
                flashTkn_,
                flashAmt_,
                0,
                0
            );
            i += 2;
        }
        if (paybackDebt_ > 0) {
            v_.targets[i] = "AAVE-V2-A";
            v_.calldatas[i] = abi.encodeWithSignature(
                "payback(address,uint256,uint256,uint256,uint256)",
                wethAddr,
                paybackDebt_,
                2,
                0,
                0
            );
            i++;
        }
        if (v_.stETHBal_ > 0 && excessDebt_ == 0) {
            v_.targets[i] = "AAVE-V2-A";
            v_.calldatas[i] = abi.encodeWithSignature(
                "deposit(address,uint256,uint256,uint256)",
                stEthAddr,
                type(uint256).max,
                0,
                0
            );
            i++;
        }
        if (extraWithdraw_ > 0) {
            v_.targets[i] = "AAVE-V2-A";
            v_.calldatas[i] = abi.encodeWithSignature(
                "withdraw(address,uint256,uint256,uint256)",
                stEthAddr,
                extraWithdraw_,
                0,
                0
            );
            v_.targets[i + 1] = "BASIC-A";
            v_.calldatas[i + 1] = abi.encodeWithSignature(
                "withdraw(address,uint256,address,uint256,uint256)",
                stEthAddr,
                extraWithdraw_,
                address(this),
                0,
                0
            );
        }

        if (excessDebt_ > 0) {
            v_.encodedFlashData = abi.encode(
                v_.targets,
                v_.calldatas
            );

            v_.flashTarget = new string[](1);
            v_.flashCalldata = new bytes[](1);
            v_.flashTarget[0] = "INSTAPOOL-C";
            v_.flashCalldata[0] = abi.encodeWithSignature(
                "flashBorrowAndCast(address,uint256,uint256,bytes,bytes)",
                flashTkn_,
                flashAmt_,
                route_,
                v_.encodedFlashData,
                "0x"
            );

            vaultDsa.cast(v_.flashTarget, v_.flashCalldata, address(this));
            require(
                getWethBorrowRate() < ratios.maxBorrowRate,
                "high-borrow-rate"
            );
        } else {
            if (j > 0) vaultDsa.cast(v_.targets, v_.calldatas, address(this));
        }

        v_.checks = new bool[](4);
        (v_.checks[0],, v_.checks[1], v_.checks[2], v_.checks[3]) = validateFinalRatio();
        if (excessDebt_ > 0) require(v_.checks[1], "position-risky-after-leverage");
        if (extraWithdraw_ > 0) require(v_.checks[0], "position-risky");
        if (excessDebt_ > 0 && extraWithdraw_ > 0) require(v_.checks[3], "position-hf-risky");

        emit rebalanceOneLog(
            flashTkn_,
            flashAmt_,
            route_,
            vaults_,
            amts_,
            excessDebt_,
            paybackDebt_,
            totalAmountToSwap_,
            extraWithdraw_,
            unitAmt_
        );
    }

    /**
     * @dev Rebalancer function for saving. To be run in times of making position less risky or to fill up the withdraw amount for users to exit
     */
    function rebalanceTwo(
        uint256 withdrawAmt_,
        address flashTkn_,
        uint256 flashAmt_,
        uint256 route_,
        uint256 saveAmt_,
        uint256 unitAmt_,
        bytes memory oneInchData_
    ) external nonReentrant onlyRebalancer {
        (,,,, bool hfIsOk_) = validateFinalRatio();
        if (hfIsOk_) {
            require(unitAmt_ > (1e18 - (2 * 1e16)), "excess-slippage"); // Here's it's 2% slippage.
        } else {
            // Here's it's 5% slippage. Only when HF is not okay. Meaning stETH got too unstable from it's original price.
            require(unitAmt_ > (1e18 - (5 * 1e16)), "excess-slippage");
        }
        uint j = 3;
        uint i = 0;
        if (flashAmt_ > 0) j += 3;
        string[] memory targets_ = new string[](j);
        bytes[] memory calldata_ = new bytes[](j);
        if (flashAmt_ > 0) {
            targets_[0] = "AAVE-V2-A";
            calldata_[0] = abi.encodeWithSignature(
                "deposit(address,uint256,uint256,uint256)",
                flashTkn_,
                flashAmt_,
                0,
                0
            );
            i++;
        }
        targets_[i] = "AAVE-V2-A";
        calldata_[i] = abi.encodeWithSignature(
            "withdraw(address,uint256,uint256,uint256)",
            stEthAddr,
            (saveAmt_ + withdrawAmt_),
            0,
            0
        );
        targets_[i + 1] = "1INCH-A";
        calldata_[i + 1] = abi.encodeWithSignature(
            "sell(address,address,uint256,uint256,bytes,uint256)",
            wethAddr,
            stEthAddr,
            saveAmt_,
            unitAmt_,
            oneInchData_,
            0
        );
        targets_[i + 2] = "AAVE-V2-A";
        calldata_[i + 2] = abi.encodeWithSignature(
            "payback(address,uint256,uint256,uint256,uint256)",
            wethAddr,
            type(uint256).max,
            2,
            0,
            0
        );
        if (flashAmt_ > 0) {
            targets_[i + 3] = "AAVE-V2-A";
            calldata_[i + 3] = abi.encodeWithSignature(
                "withdraw(address,uint256,uint256,uint256)",
                flashTkn_,
                flashAmt_,
                0,
                0
            );
            targets_[i + 4] = "INSTAPOOL-C";
            calldata_[i + 4] = abi.encodeWithSignature(
                "flashPayback(address,uint256,uint256,uint256)",
                flashTkn_,
                flashAmt_,
                0,
                0
            );
        }

        if (flashAmt_ > 0) {
            bytes memory encodedFlashData_ = abi.encode(targets_, calldata_);

            string[] memory flashTarget_ = new string[](1);
            bytes[] memory flashCalldata_ = new bytes[](1);
            flashTarget_[0] = "INSTAPOOL-C";
            flashCalldata_[0] = abi.encodeWithSignature(
                "flashBorrowAndCast(address,uint256,uint256,bytes,bytes)",
                flashTkn_,
                flashAmt_,
                route_,
                encodedFlashData_,
                "0x"
            );

            vaultDsa.cast(flashTarget_, flashCalldata_, address(this));
        } else {
            vaultDsa.cast(targets_, calldata_, address(this));
        }

        (, bool maxGapIsOk_, , bool minGapIsOk_,) = validateFinalRatio();
        if (!hfIsOk_) {
            require(minGapIsOk_, "position-over-saved");
        } else {
            require(maxGapIsOk_, "position-over-saved");
        }

        emit rebalanceTwoLog(
            withdrawAmt_,
            flashTkn_,
            flashAmt_,
            route_,
            saveAmt_,
            unitAmt_
        );
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public pure override returns (string memory) {
        return "Instadapp ETH";
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public pure override returns (string memory) {
        return "iETH";
    }

    /* 
     Deprecated
    */
    // function initialize(
    //     string memory name_,
    //     string memory symbol_,
    //     address auth_,
    //     address rebalancer_,
    //     uint256 revenueFee_,
    //     uint16[] memory ratios_
    // ) public initializer {
    //     address vaultDsaAddr_ = instaIndex.build(address(this), 2, address(this));
    //     vaultDsa = IDSA(vaultDsaAddr_);
    //     __ERC20_init(name_, symbol_);
    //     auth = auth_;
    //     isRebalancer[rebalancer_] = true;
    //     revenueFee = revenueFee_;
    //     lastRevenueExchangePrice = 1e18;
    //     // sending borrow rate in 4 decimals eg:- 300 meaning 3% and converting into 27 decimals eg:- 3 * 1e25
    //     ratios = Ratios(ratios_[0], ratios_[1], ratios_[2], uint128(ratios_[3]) * 1e23);
    // }

    receive() external payable {}
}
