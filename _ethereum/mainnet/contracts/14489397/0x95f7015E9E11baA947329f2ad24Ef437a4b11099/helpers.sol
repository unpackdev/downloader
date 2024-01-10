//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./events.sol";
import "./SafeERC20.sol";

contract Helpers is Events {
    using SafeERC20 for IERC20;

    modifier nonReentrant() {
        require(_status != 2, "ReentrancyGuard: reentrant call");
        _status = 2;
        _;
        _status = 1;
    }

    /**
     * @dev Approves the token to the spender address with allowance amount.
     * @notice Approves the token to the spender address with allowance amount.
     * @param token_ token for which allowance is to be given.
     * @param spender_ the address to which the allowance is to be given.
     * @param amount_ amount of token.
     */
    function approve(
        address token_,
        address spender_,
        uint256 amount_
    ) internal {
        TokenInterface tokenContract_ = TokenInterface(token_);
        try tokenContract_.approve(spender_, amount_) {} catch {
            IERC20 token = IERC20(token_);
            token.safeApprove(spender_, 0);
            token.safeApprove(spender_, amount_);
        }
    }

    function getWethBorrowRate()
        internal
        view
        returns (uint256 wethBorrowRate_) 
    {
        (,,,, wethBorrowRate_,,,,,) = aaveProtocolDataProvider
            .getReserveData(wethAddr);
    }

    function getStEthCollateralAmount()
        internal
        view
        returns (uint256 stEthAmount_)
    {
        stEthAmount_ = astethToken.balanceOf(address(vaultDsa));
    }

    function getWethDebtAmount()
        internal
        view
        returns (uint256 wethDebtAmount_)
    {
        wethDebtAmount_ = awethVariableDebtToken.balanceOf(address(vaultDsa));
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

    // not substracting revenue here
    function netAssets() public view returns (
        uint netCollateral_,
        uint netBorrow_,
        BalVariables memory balances_,
        uint netSupply_,
        uint netBal_
    ) {
        netCollateral_ = getStEthCollateralAmount();
        netBorrow_ = getWethDebtAmount();
        balances_ = getIdealBalances();
        netSupply_ = netCollateral_ + balances_.totalBal;
        netBal_ = netSupply_ - netBorrow_;
    }

    function getCurrentExchangePrice()
        public
        view
        returns (
            uint256 exchangePrice_,
            uint256 newRevenue_
        )
    {
        (,,,, uint256 netBal_) = netAssets();
        netBal_ = netBal_ - revenue;
        uint totalSupply_ = totalSupply();
        uint exchangePriceWithRevenue_;
        if (totalSupply_ != 0) {
            exchangePriceWithRevenue_ = (netBal_ * 1e18) / totalSupply_;
        } else {
            exchangePriceWithRevenue_ = 1e18;
        }
        // Only calculate revenue if there's a profit
        if (exchangePriceWithRevenue_ > lastRevenueExchangePrice) {
            uint revenueCut_ = ((exchangePriceWithRevenue_ - lastRevenueExchangePrice) * revenueFee) / 10000; // 10% revenue fee cut
            newRevenue_ = revenueCut_ * netBal_ / 1e18;
            exchangePrice_ = exchangePriceWithRevenue_ - revenueCut_;
        } else {
            exchangePrice_ = exchangePriceWithRevenue_;
        }
    }

    function validateFinalRatio() internal view returns (bool maxIsOk_, bool minIsOk_, bool minGapIsOk_) {
        // Not substracting revenue here as it can also help save position.
        (uint netCollateral_, uint netBorrow_, , uint netSupply_,) = netAssets();
        uint ratioMax_ = (netBorrow_ * 1e4) / netCollateral_; // Aave position ratio should not go above max limit
        maxIsOk_ = ratios.maxLimit > ratioMax_;
        uint ratioMin_ = (netBorrow_ * 1e4) / netSupply_; // net ratio (position + ideal) should not go above min limit
        minIsOk_ = ratios.minLimit > ratioMin_;
        minGapIsOk_ = ratios.minLimitGap < ratioMin_;
    }

}
