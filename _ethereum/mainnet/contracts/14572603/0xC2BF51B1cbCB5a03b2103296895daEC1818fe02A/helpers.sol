//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./variables.sol";

contract Helpers is Variables {
    /**
     * @dev reentrancy gaurd.
     */
    modifier nonReentrant() {
        require(_status != 2, "ReentrancyGuard: reentrant call");
        _status = 2;
        _;
        _status = 1;
    }

    /**
     * @dev Helper function to get current eth borrow rate on aave.
     */
    function getWethBorrowRate()
        internal
        view
        returns (uint256 wethBorrowRate_)
    {
        (, , , , wethBorrowRate_, , , , , ) = aaveProtocolDataProvider
            .getReserveData(address(wethContract));
    }

    /**
     * @dev Helper function to get current token collateral on aave.
     */
    function getTokenCollateralAmount()
        internal
        view
        returns (uint256 tokenAmount_)
    {
        tokenAmount_ = _atoken.balanceOf(address(_vaultDsa));
    }

    /**
     * @dev Helper function to get current steth collateral on aave.
     */
    function getStethCollateralAmount()
        internal
        view
        returns (uint256 stEthAmount_)
    {
        stEthAmount_ = astethToken.balanceOf(address(_vaultDsa));
    }

    /**
     * @dev Helper function to get current eth debt on aave.
     */
    function getWethDebtAmount()
        internal
        view
        returns (uint256 wethDebtAmount_)
    {
        wethDebtAmount_ = awethVariableDebtToken.balanceOf(address(_vaultDsa));
    }

    /**
     * @dev Helper function to token balances of everywhere.
     */
    function getVaultBalances()
        public
        view
        returns (
            uint256 tokenCollateralAmt_,
            uint256 stethCollateralAmt_,
            uint256 wethDebtAmt_,
            uint256 tokenVaultBal_,
            uint256 tokenDSABal_,
            uint256 netTokenBal_
        )
    {
        tokenCollateralAmt_ = getTokenCollateralAmount();
        stethCollateralAmt_ = getStethCollateralAmount();
        wethDebtAmt_ = getWethDebtAmount();
        tokenVaultBal_ = _token.balanceOf(address(this));
        tokenDSABal_ = _token.balanceOf(address(_vaultDsa));
        netTokenBal_ = tokenCollateralAmt_ + tokenVaultBal_ + tokenDSABal_;
    }

    // returns net eth. net stETH + ETH - net ETH debt.
    function getNewProfits() public view returns (uint256 profits_) {
        uint256 stEthCol_ = getStethCollateralAmount();
        uint256 stEthDsaBal_ = stethContract.balanceOf(address(_vaultDsa));
        uint256 wethDsaBal_ = wethContract.balanceOf(address(_vaultDsa));
        uint256 positiveEth_ = stEthCol_ + stEthDsaBal_ + wethDsaBal_;
        uint256 negativeEth_ = getWethDebtAmount() + _revenueEth;
        profits_ = negativeEth_ < positiveEth_
            ? positiveEth_ - negativeEth_
            : 0;
    }

    /**
     * @dev Helper function to get current exchange price and new revenue generated.
     */
    function getCurrentExchangePrice()
        public
        view
        returns (uint256 exchangePrice_, uint256 newTokenRevenue_)
    {
        // net token balance is total balance. stETH collateral & ETH debt cancels out each other.
        (, , , , , uint256 netTokenBalance_) = getVaultBalances();
        netTokenBalance_ -= _revenue;
        uint256 totalSupply_ = totalSupply();
        uint256 exchangePriceWithRevenue_;
        if (totalSupply_ != 0) {
            exchangePriceWithRevenue_ =
                (netTokenBalance_ * 1e18) /
                totalSupply_;
        } else {
            exchangePriceWithRevenue_ = 1e18;
        }
        // Only calculate revenue if there's a profit
        if (exchangePriceWithRevenue_ > _lastRevenueExchangePrice) {
            uint256 revenueCut_ = ((exchangePriceWithRevenue_ -
                _lastRevenueExchangePrice) * _revenueFee) / 10000; // 10% revenue fee cut
            newTokenRevenue_ = (revenueCut_ * netTokenBalance_) / 1e18;
            exchangePrice_ = exchangePriceWithRevenue_ - revenueCut_;
        } else {
            exchangePrice_ = exchangePriceWithRevenue_;
        }
    }

    /**
     * @dev Helper function to validate the safety of aave position after rebalancing.
     */
    function validateFinalPosition()
        internal
        view
        returns (
            bool criticalIsOk_,
            bool criticalGapIsOk_,
            bool minIsOk_,
            bool minGapIsOk_
        )
    {
        (
            uint256 tokenColAmt_,
            uint256 stethColAmt_,
            uint256 wethDebt_,
            ,
            ,
            uint256 netTokenBal_
        ) = getVaultBalances();

        uint256 ethCoveringDebt_ = (stethColAmt_ * _ratios.stEthLimit) / 10000;

        uint256 excessDebt_ = ethCoveringDebt_ < wethDebt_
            ? wethDebt_ - ethCoveringDebt_
            : 0;

        if (excessDebt_ > 0) {
            // TODO: add a fallback oracle fetching price from chainlink in case Aave changes oracle in future or in Aave v3?
            uint256 tokenPriceInEth_ = IAavePriceOracle(
                aaveAddressProvider.getPriceOracle()
            ).getAssetPrice(address(_token));

            uint256 netTokenColInEth_ = (tokenColAmt_ * tokenPriceInEth_) /
                (10**_tokenDecimals);
            uint256 netTokenSupplyInEth_ = (netTokenBal_ * tokenPriceInEth_) /
                (10**_tokenDecimals);

            uint256 ratioMax_ = (excessDebt_ * 10000) / netTokenColInEth_;
            uint256 ratioMin_ = (excessDebt_ * 10000) / netTokenSupplyInEth_;

            criticalIsOk_ = ratioMax_ < _ratios.maxLimit;
            criticalGapIsOk_ = ratioMax_ > _ratios.maxLimitGap;
            minIsOk_ = ratioMin_ < _ratios.minLimit;
            minGapIsOk_ = ratioMin_ > _ratios.minLimitGap;
        } else {
            criticalIsOk_ = true;
            minIsOk_ = true;
        }
    }

    /**
     * @dev Helper function to validate if the leverage amount is divided correctly amount other-vault-swaps and 1inch-swap .
     */
    function validateLeverageAmt(
        address[] memory vaults_,
        uint256[] memory amts_,
        uint256 leverageAmt_,
        uint256 swapAmt_
    ) internal pure returns (bool isOk_) {
        uint256 l_ = vaults_.length;
        isOk_ = l_ == amts_.length;
        if (isOk_) {
            uint256 totalAmt_ = swapAmt_;
            for (uint256 i = 0; i < l_; i++) {
                totalAmt_ = totalAmt_ + amts_[i];
            }
            isOk_ = totalAmt_ <= leverageAmt_; // total amount should not be more than leverage amount
            isOk_ = isOk_ && ((leverageAmt_ * 9999) / 10000) < totalAmt_; // total amount should be more than (0.9999 * leverage amount). 0.01% slippage gap.
        }
    }
}
