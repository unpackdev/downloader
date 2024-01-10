//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./helpers.sol";

contract CoreHelpers is Helpers {
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
            uint256 newRevenue_,
            ,
        ) = getCurrentExchangePrice(); // TODO: Update revenue and then return the updated price
        updateStorage(exchangePrice_, newRevenue_);
        if (isEth_) {
            TokenInterface(wethAddr).deposit{value: amount_}();
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
        // Log event
    }

    function withdrawHelper(
        uint amount_,
        uint limit_,
        uint totalBal_
    ) internal pure returns (
        uint,
        uint,
        uint,
        uint
    ) {
        uint transferAmt_;
        if (limit_ > amount_) {
            transferAmt_ = amount_;
            limit_ = limit_ - amount_;
            amount_ = 0;
            totalBal_ = totalBal_ - amount_;
        } else {
            transferAmt_ = limit_;
            limit_ = 0;
            amount_ = amount_ - limit_;
            totalBal_ = totalBal_ - limit_;
        }
        return (amount_, limit_, totalBal_, transferAmt_);
    }

    function withdrawFinal(
        uint amount_,
        BalVariables memory balances_,
        address to_
    ) internal returns (
        uint,
        BalVariables memory 
    ) {
        require(amount_ > 0, "amount-invalid");
        uint transferAmt_;
        string[] memory targets_ = new string[](1);
        bytes[] memory calldata_ = new bytes[](1);
        if (balances_.wethVaultBal > 10) {
            (amount_, balances_.wethVaultBal, balances_.totalBal, transferAmt_) =  withdrawHelper(amount_, balances_.wethVaultBal, balances_.totalBal);
            IERC20(wethAddr).transfer(to_, transferAmt_);
        }
        if (balances_.wethDsaBal > 10 && amount_ > 0) {
            (amount_, balances_.wethDsaBal, balances_.totalBal, transferAmt_) =  withdrawHelper(amount_, balances_.wethDsaBal, balances_.totalBal);
            targets_[0] = "BASIC-A";
            calldata_[0] = abi.encodeWithSignature("withdraw(address,uint256,address,uint256,uint256)", wethAddr, transferAmt_, to_, 0, 0);
            vaultDsa.cast(targets_, calldata_, address(this));
        }
        if (balances_.stethVaultBal > 10 && amount_ > 0) {
            (amount_, balances_.stethVaultBal, balances_.totalBal, transferAmt_) =  withdrawHelper(amount_, balances_.stethVaultBal, balances_.totalBal);
            IERC20(stEthAddr).transfer(to_, transferAmt_);
        }
        if (balances_.stethDsaBal > 10 && amount_ > 0) {
            (amount_, balances_.stethDsaBal, balances_.totalBal, transferAmt_) =  withdrawHelper(amount_, balances_.stethDsaBal, balances_.totalBal);
            targets_[0] = "BASIC-A";
            calldata_[0] = abi.encodeWithSignature("withdraw(address,uint256,address,uint256,uint256)", stEthAddr, transferAmt_, to_, 0, 0);
            vaultDsa.cast(targets_, calldata_, address(this));
        }
        return (amount_, balances_);
    }

}

contract InstaVaultImplementation is CoreHelpers {
    using SafeERC20 for IERC20;

    function userWithdrawals(address user_) external view returns (Withdraw[] memory) {
        return userWithdrawAwaiting[user_];
    }
    
    function supplyEth(address to_) external payable nonReentrant returns (uint vtokenAmount_) {
        uint amount_ = msg.value;
        vtokenAmount_ = supplyInternal(
            ethAddr,
            amount_,
            to_,
            true
        );
        // TODO: Log event
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
        // TODO: Log event
    }

    // activate withdrawal time
    function withdrawStart(
        uint256 amount_,
        address to_
    ) external nonReentrant returns (uint256 vtokenAmount_) {
        require(amount_ != 0, "amount cannot be zero");
        (
            uint256 exchangePrice_,
            uint256 newRevenue_,
            ,
        ) = getCurrentExchangePrice(); // TODO: Update revenue and then return the updated price
        updateStorage(exchangePrice_, newRevenue_);
        if (amount_ == type(uint).max) {
            vtokenAmount_ = balanceOf(msg.sender);
            amount_ = vtokenAmount_ * exchangePrice_ / 1e18;
        } else {
            vtokenAmount_ = (amount_ * 1e18) / exchangePrice_;
        }
        _burn(msg.sender, vtokenAmount_);
        userWithdrawAwaiting[to_].push(Withdraw(uint128(amount_), uint128(block.timestamp + withdrawalTime)));
        totalWithdrawAwaiting = totalWithdrawAwaiting + amount_;
        // TODO: emit event
    }

    function withdrawClaim(
        uint[] memory indexes,
        address to_
    ) external nonReentrant returns (uint256 totalWithdraw_) {
        // TODO: Should we swap and withdraw in ETH
        BalVariables memory balances_ = getIdealBalances();
        for (uint i = 0; i < indexes.length; i++) {
            uint256 time_ = userWithdrawAwaiting[to_][indexes[i]].time;
            uint256 amount_ = userWithdrawAwaiting[to_][indexes[i]].amount;
            require(time_ < block.timestamp && amount_ > 0, "wrong-withdrawal");
            totalWithdraw_ = totalWithdraw_ + amount_;
            (amount_, balances_) = withdrawFinal(
                amount_,
                balances_,
                to_
            );
            userWithdrawAwaiting[to_][indexes[i]].amount = uint128(amount_);
            if (amount_ != 0) {
                totalWithdraw_ = totalWithdraw_ - amount_;
                break;
            }
        }
        totalWithdrawAwaiting = totalWithdrawAwaiting - totalWithdraw_;
        // TODO: emit event
    }

    function initialize(
        string memory name_,
        string memory symbol_,
        uint256 safeDistancePercentage_,
        uint256 withdrawalTime_,
        uint256 revenueFee_
    ) public initializer {
        address vaultDsaAddr_ = instaIndex.build(address(this), 2, address(0));
        vaultDsa = IDSA(vaultDsaAddr_);
        __ERC20_init(name_, symbol_);
        safeDistancePercentage = safeDistancePercentage_;
        withdrawalTime = withdrawalTime_;
        revenueFee = revenueFee_;
        lastRevenueExchangePrice = 1e18;
        _status = 1;
    }

}
