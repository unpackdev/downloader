//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./variables.sol";
import "./SafeERC20.sol";

contract Helpers is Variables {
    using SafeERC20 for IERC20;

    modifier nonReentrant() {
        require(_status != 2, "ReentrancyGuard: reentrant call");
        _status = 2;
        _;
        _status = 1;
    }

    function getStEthCollateralAmount()
        internal
        view
        returns (uint256 stEthAmount_)
    {
        (stEthAmount_, , , , , , , , ) = aaveProtocolDataProvider
            .getUserReserveData(stEthAddr, address(vaultDsa));
    }

    function getWethDebtAmount()
        internal
        view
        returns (uint256 ethDebtAmount_)
    {
        (, , ethDebtAmount_, , , , , , ) = aaveProtocolDataProvider
            .getUserReserveData(wethAddr, address(vaultDsa));
    }

    struct BalVariables {
        uint wethVaultBal;
        uint wethDsaBal;
        uint stethVaultBal;
        uint stethDsaBal;
        uint totalBal;
    }

    function getIdealBalances() public view returns (
        BalVariables memory balances_
    ) {
        IERC20 wethCon_ = IERC20(wethAddr);
        IERC20 stethCon_ = IERC20(stEthAddr);
        balances_.wethVaultBal = wethCon_.balanceOf(address(this));
        balances_.wethDsaBal = wethCon_.balanceOf(address(vaultDsa));
        balances_.stethVaultBal = stethCon_.balanceOf(address(this));
        balances_.stethDsaBal = stethCon_.balanceOf(address(vaultDsa));
        balances_.totalBal = balances_.wethVaultBal + balances_.wethDsaBal + balances_.stethVaultBal + balances_.stethDsaBal;
    }

    function getNetExcessBalance() public view returns (
        uint excessBal_,
        uint excessWithdraw_
    ) {
        BalVariables memory balances_ = getIdealBalances();
        excessBal_ = balances_.totalBal;
        excessWithdraw_ = totalWithdrawAwaiting;
        if (excessWithdraw_ >= excessBal_) {
            excessBal_ = 0;
            excessWithdraw_ = excessWithdraw_ - excessBal_;
        } else {
            excessBal_ = excessBal_ - excessWithdraw_;
            excessWithdraw_ = 0;
        }
    }

    function getCurrentExchangePrice()
        public
        view
        returns (
            uint256 exchangePrice_,
            uint256 newRevenue_,
            uint256 stEthCollateralAmount_,
            uint256 wethDebtAmount_
        )
    {
        stEthCollateralAmount_ = getStEthCollateralAmount();
        wethDebtAmount_ = getWethDebtAmount();
        (uint excessBal_, uint excessWithdraw_) = getNetExcessBalance();
        uint256 netSupply = stEthCollateralAmount_ +
            excessBal_ -
            wethDebtAmount_ -
            excessWithdraw_ -
            revenue;
        uint totalSupply_ = totalSupply();
        uint exchangePriceWithRevenue_;
        if (totalSupply_ != 0) {
            exchangePriceWithRevenue_ = (netSupply * 1e18) / totalSupply_;
        } else {
            exchangePriceWithRevenue_ = 1e18;
        }
        // Only calculate revenue if there's a profit
        if (exchangePriceWithRevenue_ > lastRevenueExchangePrice) {
            uint revenueCut_ = ((exchangePriceWithRevenue_ - lastRevenueExchangePrice) * revenueFee) / 10000; // 10% revenue fee cut
            newRevenue_ = revenueCut_ * netSupply / 1e18;
            exchangePrice_ = exchangePriceWithRevenue_ - revenueCut_;
        } else {
            exchangePrice_ = exchangePriceWithRevenue_;
        }
    }

}
