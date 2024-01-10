//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./helpers.sol";

contract AdminModule is Helpers {

    modifier onlyOwner() {
        require(owner == msg.sender, "only owner");
        _;
    }

    modifier onlyAuth() {
        require(isAuth[msg.sender], "only owner");
        _;
    }

    function updateOwner(address owner_) external onlyOwner {
        owner = owner_;
        emit updateOwnerLog(owner_);
    }

    function updateAuth(address auth_, bool isAuth_) external onlyOwner {
        isAuth[auth_] = isAuth_;
        emit updateAuthLog(auth_, isAuth_);
    }

    function updateRates(uint16[] memory rates_) external onlyOwner {
        ratios = Ratios(rates_[0], rates_[1], rates_[2], rates_[3]);
        emit updateRatesLog(rates_[0], rates_[1], rates_[2], rates_[3]);
    }

    function updateRevenueFee(uint newRevenueFee_) external onlyOwner {
        uint oldRevenueFee_ = revenueFee;
        revenueFee = newRevenueFee_;
        emit updateRevenueFeeLog(oldRevenueFee_, newRevenueFee_);
    }

    function updateRatios(uint16[] memory ratios_) external onlyOwner {
        ratios = Ratios(ratios_[0], ratios_[1], ratios_[2], uint128(ratios_[3]) * 1e23);
        emit updateRatesLog(ratios_[0], ratios_[1], ratios_[2], uint128(ratios_[3]) * 1e23);
    }

}

contract CoreHelpers is AdminModule {
    using SafeERC20 for IERC20;

    function updateStorage(
        uint256 exchangePrice_,
        uint256 newRevenue_
    ) internal {
        if (exchangePrice_ > lastRevenueExchangePrice) {
            lastRevenueExchangePrice = exchangePrice_;
            revenue = revenue + newRevenue_;
        }
    }

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
                IERC20(token_).safeTransferFrom(msg.sender, address(this), amount_);
            } else if (token_ == wethAddr) {
                IERC20(token_).safeTransferFrom(msg.sender, address(this), amount_);
            } else {
                revert("wrong-token");
            }
        }
        vtokenAmount_ = (amount_ * 1e18) / exchangePrice_;
        _mint(to_, vtokenAmount_);
        emit supplyLog(token_, amount_, to_);
    }

    function withdrawHelper(
        uint amount_,
        uint limit_
    ) internal pure returns (
        uint,
        uint
    ) {
        uint transferAmt_;
        if (limit_ > amount_) {
            transferAmt_ = amount_;
            amount_ = 0;
        } else {
            transferAmt_ = limit_;
            amount_ = amount_ - limit_;
        }
        return (amount_, transferAmt_);
    }

    function withdrawFinal(
        uint amount_
    ) public view returns (uint[] memory transferAmts_) {
        require(amount_ > 0, "amount-invalid");

        (uint netCollateral_, uint netBorrow_, BalVariables memory balances_,,) = netAssets();

        uint ratio_ = netCollateral_ > 0 ? (netBorrow_ * 1e4) / netCollateral_ : 0;
        require(ratio_ < ratios.maxLimit, "already-risky"); // don't allow any withdrawal if Aave position is risky

        require(amount_ < balances_.totalBal, "excess-withdrawal");

        transferAmts_ = new uint[](4);
        if (balances_.wethVaultBal > 10) {
            (amount_, transferAmts_[0]) =  withdrawHelper(amount_, balances_.wethVaultBal);
        }
        if (balances_.wethDsaBal > 10 && amount_ > 0) {
            (amount_, transferAmts_[1]) =  withdrawHelper(amount_, balances_.wethDsaBal);
        }
        if (balances_.stethVaultBal > 10 && amount_ > 0) {
            (amount_, transferAmts_[2]) =  withdrawHelper(amount_, balances_.stethVaultBal);
        }
        if (balances_.stethDsaBal > 10 && amount_ > 0) {
            (amount_, transferAmts_[3]) =  withdrawHelper(amount_, balances_.stethDsaBal);
        }
    }

    function withdrawTransfers(uint amount_, uint[] memory transferAmts_) internal returns (uint wethAmt_, uint stEthAmt_) {
        wethAmt_ = transferAmts_[0] + transferAmts_[1];
        stEthAmt_ = transferAmts_[2] + transferAmts_[3];
        uint totalTransferAmount_ = wethAmt_ + stEthAmt_;
        // adding final condition in the end in case we fucked up anywhere in above function then this will surely fail
        // Makes the chances of having a bug to lose asset 0 in withdrawFinal()
        require(amount_ == totalTransferAmount_, "transfers-not-valid");
        // batching up spells and withdrawing all the required asset from DSA to vault at once
        uint i;
        uint j;
        if (transferAmts_[1] > 0 && transferAmts_[3] > 0) {
            i = 2;
        } else if (transferAmts_[3] > 0 || transferAmts_[1] > 0) {
            i = 1;
        }
        string[] memory targets_ = new string[](i);
        bytes[] memory calldata_ = new bytes[](i);
        if (transferAmts_[1] > 0) {
            targets_[j] = "BASIC-A";
            calldata_[j] = abi.encodeWithSignature("withdraw(address,uint256,address,uint256,uint256)", wethAddr, transferAmts_[1], address(this), 0, 0);
            j++;
        }
        if (transferAmts_[3] > 0) {
            targets_[j] = "BASIC-A";
            calldata_[j] = abi.encodeWithSignature("withdraw(address,uint256,address,uint256,uint256)", stEthAddr, transferAmts_[3], address(this), 0, 0);
            j++;
        }
        if (i > 0) vaultDsa.cast(targets_, calldata_, address(this));
    }

}

contract InstaVaultImplementation is CoreHelpers {
    using SafeERC20 for IERC20;
    
    function supplyEth(address to_) external payable nonReentrant returns (uint vtokenAmount_) {
        uint amount_ = msg.value;
        vtokenAmount_ = supplyInternal(
            ethAddr,
            amount_,
            to_,
            true
        );
    }

    function supply(
        address token_,
        uint256 amount_,
        address to_
    ) external nonReentrant returns (uint256 vtokenAmount_) {
        vtokenAmount_ = supplyInternal(
            token_,
            amount_,
            to_,
            false
        );
    }

    // gives preference to weth in case of withdrawal
    function withdraw(
        uint256 amount_,
        address to_
    ) external nonReentrant returns (uint256 vtokenAmount_) {
        require(amount_ != 0, "amount cannot be zero");

        (
            uint256 exchangePrice_,
            uint256 newRevenue_
        ) = getCurrentExchangePrice();
        updateStorage(exchangePrice_, newRevenue_);

        if (amount_ == type(uint).max) {
            vtokenAmount_ = balanceOf(msg.sender);
            amount_ = vtokenAmount_ * exchangePrice_ / 1e18;
        } else {
            vtokenAmount_ = (amount_ * 1e18) / exchangePrice_;
        }

        _burn(msg.sender, vtokenAmount_);

        uint[] memory transferAmts_ = withdrawFinal(amount_);

        (uint wethAmt_, uint stEthAmt_) = withdrawTransfers(amount_, transferAmts_);

        if (wethAmt_ > 0) {
            // withdraw weth and sending ETH to user
            wethCoreContract.withdraw(wethAmt_);
            payable(to_).call{value: wethAmt_}("");
        }
        if (stEthAmt_ > 0) stEthContract.safeTransfer(to_, stEthAmt_);

        emit withdrawLog(amount_, to_);
    }

    struct RebalanceOneVariables {
        uint stETHBal_;
        string[] targets;
        bytes[] calldatas;
        bool[] checks;
    }

    // rebalance for leveraging
    function rebalanceOne(
        address flashTkn_,
        uint flashAmt_,
        uint route_,
        uint excessDebt_,
        uint paybackDebt_,
        uint totalAmountToSwap_,
        uint extraWithdraw_,
        uint unitAmt_,
        bytes memory oneInchData_
    ) external nonReentrant onlyAuth {
        if (excessDebt_ < 1e14) excessDebt_ = 0;
        if (paybackDebt_ < 1e14) paybackDebt_ = 0;
        if (totalAmountToSwap_ < 1e14) totalAmountToSwap_ = 0;
        if (extraWithdraw_ < 1e14) extraWithdraw_ = 0;

        require(!(excessDebt_ > 0 && paybackDebt_ > 0), "cannot-borrow-and-payback-at-once");
        require(!(totalAmountToSwap_ > 0 && paybackDebt_ > 0), "cannot-swap-and-payback-at-once");

        RebalanceOneVariables memory v_;

        BalVariables memory balances_ = getIdealBalances();

        if (balances_.wethVaultBal > 1e14) wethContract.safeTransfer(address(vaultDsa), balances_.wethVaultBal);
        if (balances_.stethVaultBal > 1e14) stEthContract.safeTransfer(address(vaultDsa), balances_.stethVaultBal);
        v_.stETHBal_ = balances_.stethVaultBal + balances_.stethDsaBal;
        if (v_.stETHBal_ < 1e14) v_.stETHBal_ = 0;

        uint i;
        uint j;
        if (excessDebt_ > 0) j += 6;
        if (paybackDebt_ > 0) j += 1;
        if (v_.stETHBal_ > 0) j += 1;
        if (extraWithdraw_ > 0) j += 2;
        v_.targets = new string[](j);
        v_.calldatas = new bytes[](j);
        if (excessDebt_ > 0) {
            require(unitAmt_ > (1e18 - 10), "invalid-unit-amt");
            require(totalAmountToSwap_ > 0, "invalid-swap-amt");
            v_.targets[0] = "AAVE-V2-A";
            v_.calldatas[0] = abi.encodeWithSignature("deposit(address,uint256,uint256,uint256)", flashTkn_, flashAmt_, 0, 0);
            v_.targets[1] = "AAVE-V2-A";
            v_.calldatas[1] = abi.encodeWithSignature("borrow(address,uint256,uint256,uint256,uint256)", wethAddr, excessDebt_, 2, 0, 0);
            v_.targets[2] = "1INCH-A";
            v_.calldatas[2] = abi.encodeWithSignature("sell(address,address,uint256,uint256,bytes,uint256)", wethAddr, stEthAddr, totalAmountToSwap_, unitAmt_, oneInchData_, 0);
            v_.targets[3] = "AAVE-V2-A";
            v_.calldatas[3] = abi.encodeWithSignature("deposit(address,uint256,uint256,uint256)", stEthAddr, type(uint).max, 0, 0);
            v_.targets[4] = "AAVE-V2-A";
            v_.calldatas[4] = abi.encodeWithSignature("withdraw(address,uint256,uint256,uint256)", flashTkn_, flashAmt_, 0, 0);
            v_.targets[5] = "INSTAPOOL-C";
            v_.calldatas[5] = abi.encodeWithSignature("flashPayback(address,uint256,uint256,uint256)", flashTkn_, flashAmt_, 0, 0);
            i = 6;
        }
        if (paybackDebt_ > 0) {
            v_.targets[i] = "AAVE-V2-A";
            v_.calldatas[i] = abi.encodeWithSignature("payback(address,uint256,uint256,uint256,uint256)", wethAddr, paybackDebt_, 2, 0, 0);
            i++;
        }
        if (v_.stETHBal_ > 0) {
            v_.targets[i] = "AAVE-V2-A";
            v_.calldatas[i] = abi.encodeWithSignature("deposit(address,uint256,uint256,uint256)", stEthAddr, type(uint).max, 0, 0);
            i++;
        }
        if (extraWithdraw_ > 0) {
            v_.targets[i] = "AAVE-V2-A";
            v_.calldatas[i] = abi.encodeWithSignature("withdraw(address,uint256,uint256,uint256)", stEthAddr, extraWithdraw_, 0, 0);
            v_.targets[i + 1] = "BASIC-A";
            v_.calldatas[i + 1] = abi.encodeWithSignature("withdraw(address,uint256,address,uint256,uint256)", stEthAddr, extraWithdraw_, address(this), 0, 0);
        }

        if (excessDebt_ > 0) {
            bytes memory encodedFlashData_ = abi.encode(v_.targets, v_.calldatas);

            string[] memory flashTarget_ = new string[](1);
            bytes[] memory flashCalldata_ = new bytes[](1);
            flashTarget_[0] = "INSTAPOOL-C";
            flashCalldata_[0] = abi.encodeWithSignature("flashBorrowAndCast(address,uint256,uint256,bytes,bytes)", flashTkn_, flashAmt_, route_, encodedFlashData_, "0x");

            vaultDsa.cast(flashTarget_, flashCalldata_, address(this));
            require(getWethBorrowRate() < ratios.maxBorrowRate, "high-borrow-rate");
        } else {
            if (j > 0) vaultDsa.cast(v_.targets, v_.calldatas, address(this));
        }

        v_.checks = new bool[](3);
        (v_.checks[0], v_.checks[1], v_.checks[2]) = validateFinalRatio();
        if (excessDebt_ > 0) {
            require(v_.checks[1], "final assets after leveraging");
        }
        if (extraWithdraw_ > 0) {
            require(v_.checks[0], "position risky");
        }
        require(v_.checks[2], "ratio is too low");
        
        emit rebalanceOneLog(flashTkn_, flashAmt_, route_, excessDebt_, paybackDebt_, totalAmountToSwap_, extraWithdraw_, unitAmt_);
    }

    // rebalance for saving. To be run in times of making position less risky or to fill up the withdraw amount for users to exit
    function rebalanceTwo(
        uint withdrawAmt_,
        address flashTkn_,
        uint flashAmt_,
        uint route_,
        uint saveAmt_,
        uint unitAmt_,
        bytes memory oneInchData_
    ) external nonReentrant onlyOwner {
        string[] memory targets_ = new string[](6);
        bytes[] memory calldata_ = new bytes[](6);
        targets_[0] = "AAVE-V2-A";
        calldata_[0] = abi.encodeWithSignature("deposit(address,uint256,uint256,uint256)", flashTkn_, flashAmt_, 0, 0);
        targets_[1] = "AAVE-V2-A";
        calldata_[1] = abi.encodeWithSignature("withdraw(address,uint256,uint256,uint256)", stEthAddr, (saveAmt_ + withdrawAmt_), 0, 0);
        targets_[2] = "1INCH-A";
        calldata_[2] = abi.encodeWithSignature("sell(address,address,uint256,uint256,bytes,uint256)", stEthAddr, wethAddr, saveAmt_, unitAmt_, oneInchData_, 0);
        targets_[3] = "AAVE-V2-A";
        calldata_[3] = abi.encodeWithSignature("payback(address,uint256,uint256,uint256,uint256)", wethAddr, 0, 2, type(uint).max, 0);
        targets_[4] = "AAVE-V2-A";
        calldata_[4] = abi.encodeWithSignature("withdraw(address,uint256,uint256,uint256)", flashTkn_, flashAmt_, 0, 0);
        targets_[5] = "INSTAPOOL-C";
        calldata_[5] = abi.encodeWithSignature("flashPayback(address,uint256,uint256,uint256)", flashTkn_, flashAmt_, 0, 0);

        bytes memory encodedFlashData_ = abi.encode(targets_, calldata_);

        string[] memory flashTarget_ = new string[](1);
        bytes[] memory flashCalldata_ = new bytes[](1);
        flashTarget_[0] = "INSTAPOOL-C";
        flashCalldata_[0] = abi.encodeWithSignature("flashBorrowAndCast(address,uint256,uint256,bytes,bytes)", flashTkn_, flashAmt_, route_, encodedFlashData_, "0x");

        vaultDsa.cast(flashTarget_, flashCalldata_, address(this));

        (bool isOk_,,) = validateFinalRatio();
        require(isOk_, "position-not-risky");

        emit rebalanceTwoLog(withdrawAmt_, flashTkn_, flashAmt_, route_, saveAmt_, unitAmt_);
    }

    function initialize(
        string memory name_,
        string memory symbol_,
        address owner_,
        address auth_,
        uint256 revenueFee_,
        uint16[] memory ratios_
    ) public initializer {
        address vaultDsaAddr_ = instaIndex.build(address(this), 2, address(this));
        vaultDsa = IDSA(vaultDsaAddr_);
        __ERC20_init(name_, symbol_);
        owner = owner_;
        isAuth[auth_] = true;
        revenueFee = revenueFee_;
        lastRevenueExchangePrice = 1e18;
        // sending borrow rate in 4 decimals eg:- 300 meaning 3% and converting into 27 decimals eg:- 3 * 1e25
        ratios = Ratios(ratios_[0], ratios_[1], ratios_[2], uint128(ratios_[3]) * 1e23);
    }

    receive() external payable {}

}
