//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./interface.sol";
import "./helpers.sol";
import "./IERC20.sol";

contract InstaVaultUIResolver is Helpers {
    struct CommonVaultInfo {
        address token;
        uint8 decimals;
        uint256 userBalance;
        uint256 userBalanceStETH;
        uint256 aaveTokenSupplyRate;
        uint256 aaveWETHBorrowRate_;
        uint256 totalStEthBal;
        uint256 wethDebtAmt;
        uint256 userSupplyAmount;
        uint256 vaultTVLInAsset;
        uint256 availableWithdraw;
        uint256 revenueFee;
        VaultInterfaceToken.Ratios ratios;
    }

    /**
     * @dev Get all the info
     * @notice Get info of all the vaults and the user
     */
    function getInfoCommon(address user_, address[] memory vaults_)
        public
        view
        returns (CommonVaultInfo[] memory commonInfo_)
    {
        uint256 len_ = vaults_.length;
        commonInfo_ = new CommonVaultInfo[](vaults_.length);

        for (uint256 i = 0; i < len_; i++) {
            VaultInterfaceCommon vault_ = VaultInterfaceCommon(vaults_[i]);
            IAavePriceOracle aaveOracle_ = IAavePriceOracle(
                AAVE_ADDR_PROVIDER.getPriceOracle()
            );
            uint256 ethPriceInBaseCurrency_ = aaveOracle_.getAssetPrice(
                WETH_ADDR
            );

            if (vaults_[i] == ETH_VAULT_ADDR) {
                HelperStruct memory helper_;
                VaultInterfaceETH ethVault_ = VaultInterfaceETH(vaults_[i]);
                VaultInterfaceETH.Ratios memory ratios_ = ethVault_.ratios();

                commonInfo_[i].token = ETH_ADDR;
                commonInfo_[i].decimals = 18;
                commonInfo_[i].userBalance = user_.balance;
                commonInfo_[i].userBalanceStETH = TokenInterface(STETH_ADDR)
                    .balanceOf(user_);
                commonInfo_[i].aaveTokenSupplyRate = 0;

                VaultInterfaceETH.BalVariables memory balances_;
                (
                    helper_.stethCollateralAmt,
                    commonInfo_[i].wethDebtAmt,
                    balances_,
                    ,

                ) = ethVault_.netAssets();

                commonInfo_[i].totalStEthBal =
                    helper_.stethCollateralAmt +
                    balances_.stethDsaBal +
                    balances_.stethVaultBal;
                commonInfo_[i].availableWithdraw = balances_.totalBal;
                uint256 currentRatioMax_ = (commonInfo_[i].wethDebtAmt * 1e4) /
                    helper_.stethCollateralAmt;
                uint256 maxLimitThreshold = ratios_.maxLimit - 10; // taking 0.1% margin
                if (currentRatioMax_ < maxLimitThreshold) {
                    commonInfo_[i].availableWithdraw +=
                        helper_.stethCollateralAmt -
                        ((1e4 * commonInfo_[i].wethDebtAmt) /
                            maxLimitThreshold);
                }
                commonInfo_[i].ratios.maxLimit = ratios_.maxLimit;
                commonInfo_[i].ratios.minLimit = ratios_.minLimit;
                commonInfo_[i].ratios.minLimitGap = ratios_.minLimitGap;
                commonInfo_[i].ratios.maxBorrowRate = ratios_.maxBorrowRate;
            } else {
                VaultInterfaceToken tokenVault_ = VaultInterfaceToken(
                    vaults_[i]
                );
                commonInfo_[i].ratios = tokenVault_.ratios();

                commonInfo_[i].token = tokenVault_.token();
                commonInfo_[i].decimals = vault_.decimals();
                commonInfo_[i].userBalance = TokenInterface(
                    commonInfo_[i].token
                ).balanceOf(user_);
                commonInfo_[i].userBalanceStETH = 0;
                (
                    ,
                    ,
                    ,
                    commonInfo_[i].aaveTokenSupplyRate,
                    ,
                    ,
                    ,
                    ,
                    ,

                ) = AAVE_DATA.getReserveData(commonInfo_[i].token);

                uint256 maxLimitThreshold = (commonInfo_[i].ratios.maxLimit -
                    100) - 10; // taking 0.1% margin from withdrawLimit
                uint256 stethCollateralAmt_;

                (
                    stethCollateralAmt_,
                    commonInfo_[i].wethDebtAmt,
                    commonInfo_[i].availableWithdraw
                ) = getAmounts(
                    vaults_[i],
                    commonInfo_[i].decimals,
                    aaveOracle_.getAssetPrice(commonInfo_[i].token),
                    ethPriceInBaseCurrency_,
                    commonInfo_[i].ratios.stEthLimit,
                    maxLimitThreshold
                );

                commonInfo_[i].totalStEthBal =
                    stethCollateralAmt_ +
                    IERC20(STETH_ADDR).balanceOf(vault_.vaultDsa()) +
                    IERC20(STETH_ADDR).balanceOf(vaults_[i]);
            }

            (uint256 exchangePrice, ) = vault_.getCurrentExchangePrice();
            commonInfo_[i].userSupplyAmount =
                (vault_.balanceOf(user_) * exchangePrice) /
                1e18;

            (, , , , commonInfo_[i].aaveWETHBorrowRate_, , , , , ) = AAVE_DATA
                .getReserveData(WETH_ADDR);

            commonInfo_[i].vaultTVLInAsset =
                (vault_.totalSupply() * exchangePrice) /
                1e18;

            commonInfo_[i].revenueFee = vault_.revenueFee();
        }
    }

    struct DeleverageAndWithdrawVars {
        uint256 withdrawalFee;
        uint256 currentRatioMax;
        uint256 currentRatioMin;
        uint256 netCollateral;
        uint256 netBorrow;
        VaultInterfaceETH.BalVariables balances;
        uint256 netSupply;
        uint256 availableWithdraw;
        uint256 maxLimitThreshold;
        address tokenAddr;
        uint256 tokenCollateralAmt;
        uint256 tokenVaultBal;
        uint256 tokenDSABal;
        uint256 netTokenBal;
        uint256 idealTokenBal;
        uint256 tokenPriceInBaseCurrency;
        uint256 ethPriceInBaseCurrency;
        uint256 tokenColInEth;
        uint256 tokenSupplyInEth;
        uint256 withdrawAmtInEth;
        uint256 idealTokenBalInEth;
    }

    function getDeleverageAndWithdrawData(
        address vaultAddr_,
        uint256 withdrawAmt_
    )
        public
        view
        returns (
            address tokenAddr_,
            uint256 tokenDecimals_,
            uint256 premium,
            uint256 tokenPriceInEth_,
            uint256 exchangePrice_,
            uint256 itokenAmt_,
            uint256 deleverageAmtMax_,
            uint256 deleverageAmtMin_,
            uint256 deleverageAmtTillMinLimit_,
            uint256 deleverageAmtTillMaxLimit_
        )
    {
        DeleverageAndWithdrawVars memory v_;
        premium = deleverageAndWithdrawWrapper.premium();
        v_.withdrawalFee = VaultInterfaceCommon(vaultAddr_).withdrawalFee();
        (exchangePrice_, ) = VaultInterfaceCommon(vaultAddr_)
            .getCurrentExchangePrice();
        itokenAmt_ = (withdrawAmt_ * 1e18) / exchangePrice_;
        withdrawAmt_ = withdrawAmt_ - (withdrawAmt_ * v_.withdrawalFee) / 1e4;
        (v_.currentRatioMax, v_.currentRatioMin) = getCurrentRatios(vaultAddr_);
        tokenDecimals_ = VaultInterfaceCommon(vaultAddr_).decimals();
        if (vaultAddr_ == ETH_VAULT_ADDR) {
            tokenAddr_ = ETH_ADDR;
            tokenPriceInEth_ = 1e18;
            VaultInterfaceETH.Ratios memory ratios_ = VaultInterfaceETH(
                vaultAddr_
            ).ratios();
            (
                v_.netCollateral,
                v_.netBorrow,
                v_.balances,
                v_.netSupply,

            ) = VaultInterfaceETH(vaultAddr_).netAssets();

            v_.availableWithdraw = v_.balances.totalBal;
            v_.maxLimitThreshold = ratios_.maxLimit;
            if (v_.currentRatioMax < v_.maxLimitThreshold) {
                v_.availableWithdraw +=
                    v_.netCollateral -
                    ((1e4 * v_.netBorrow) / v_.maxLimitThreshold);
            }

            // using this deleverageAmt_ the max ratio will remain the same
            if (withdrawAmt_ > v_.balances.totalBal) {
                deleverageAmtMax_ =
                    (v_.netBorrow * (withdrawAmt_ - v_.balances.totalBal)) /
                    (v_.netCollateral - v_.netBorrow);
            } else deleverageAmtMax_ = 0;

            // using this deleverageAmt_ the min ratio will remain the same
            deleverageAmtMin_ =
                (v_.netBorrow * withdrawAmt_) /
                (v_.netSupply - v_.netBorrow);

            // using this deleverageAmt_ the max ratio will be taken to maxLimit (unless ideal balance is sufficient)
            if (
                v_.availableWithdraw <= withdrawAmt_ &&
                withdrawAmt_ > v_.balances.totalBal
            ) {
                deleverageAmtTillMaxLimit_ =
                    ((v_.netBorrow * 1e4) -
                        ((ratios_.maxLimit - 10) * // taking 0.1% margin from maxLimit
                            (v_.netSupply - withdrawAmt_))) /
                    (1e4 - (ratios_.maxLimit - 10));
            } else deleverageAmtTillMaxLimit_ = 0;

            // using this deleverageAmt_ the min ratio will be taken to minLimit
            if (v_.availableWithdraw <= withdrawAmt_) {
                deleverageAmtTillMinLimit_ =
                    ((v_.netBorrow * 1e4) -
                        (ratios_.minLimit * (v_.netSupply - withdrawAmt_))) /
                    (1e4 - ratios_.minLimit);
            } else deleverageAmtTillMinLimit_ = 0;
        } else {
            tokenAddr_ = VaultInterfaceToken(vaultAddr_).token();
            VaultInterfaceToken.Ratios memory ratios_ = VaultInterfaceToken(
                vaultAddr_
            ).ratios();
            v_.tokenAddr = VaultInterfaceToken(vaultAddr_).token();
            (
                v_.tokenCollateralAmt,
                ,
                ,
                v_.tokenVaultBal,
                v_.tokenDSABal,
                v_.netTokenBal
            ) = VaultInterfaceToken(vaultAddr_).getVaultBalances();
            v_.idealTokenBal = v_.tokenVaultBal + v_.tokenDSABal;

            IAavePriceOracle aaveOracle_ = IAavePriceOracle(
                AAVE_ADDR_PROVIDER.getPriceOracle()
            );
            v_.tokenPriceInBaseCurrency = aaveOracle_.getAssetPrice(
                v_.tokenAddr
            );
            v_.ethPriceInBaseCurrency = aaveOracle_.getAssetPrice(WETH_ADDR);
            tokenPriceInEth_ =
                (v_.tokenPriceInBaseCurrency * 1e18) /
                v_.ethPriceInBaseCurrency;
            v_.tokenColInEth =
                (v_.tokenCollateralAmt * v_.tokenPriceInBaseCurrency) /
                v_.ethPriceInBaseCurrency;
            v_.tokenSupplyInEth =
                (v_.netTokenBal * v_.tokenPriceInBaseCurrency) /
                v_.ethPriceInBaseCurrency;
            v_.withdrawAmtInEth =
                (withdrawAmt_ * v_.tokenPriceInBaseCurrency) /
                v_.ethPriceInBaseCurrency;
            v_.idealTokenBalInEth =
                (v_.idealTokenBal * v_.tokenPriceInBaseCurrency) /
                v_.ethPriceInBaseCurrency;

            // using this deleverageAmt_ the max ratio will remain the same
            if (v_.withdrawAmtInEth > v_.idealTokenBalInEth) {
                deleverageAmtMax_ =
                    (v_.currentRatioMax *
                        (v_.withdrawAmtInEth - v_.idealTokenBalInEth)) /
                    (10000 - ratios_.stEthLimit);
            } else deleverageAmtMax_ = 0;

            // using this deleverageAmt_ the min ratio will remain the same
            deleverageAmtMin_ =
                (v_.currentRatioMin * v_.withdrawAmtInEth) /
                (10000 - ratios_.stEthLimit);

            v_.availableWithdraw = v_.tokenVaultBal + v_.tokenDSABal;
            v_.maxLimitThreshold = ratios_.maxLimit - 100;
            if (v_.currentRatioMax < v_.maxLimitThreshold) {
                v_.availableWithdraw += (((v_.maxLimitThreshold -
                    v_.currentRatioMax) * v_.tokenCollateralAmt) /
                    v_.maxLimitThreshold);
            }

            // using this deleverageAmt_ the max ratio will be taken to maxLimit (unless ideal balance is sufficient)
            if (
                v_.availableWithdraw <= withdrawAmt_ &&
                withdrawAmt_ > v_.idealTokenBal
            ) {
                deleverageAmtTillMaxLimit_ =
                    ((v_.currentRatioMax * v_.tokenColInEth) -
                        (ratios_.maxLimit *
                            (v_.tokenColInEth -
                                (v_.withdrawAmtInEth -
                                    v_.idealTokenBalInEth)))) /
                    (10000 - ratios_.stEthLimit);
            } else deleverageAmtTillMaxLimit_ = 0;

            // using this deleverageAmt_ the min ratio will be taken to minLimit
            if (v_.availableWithdraw <= withdrawAmt_) {
                deleverageAmtTillMinLimit_ =
                    ((v_.currentRatioMin * v_.tokenSupplyInEth) -
                        (ratios_.minLimit *
                            (v_.tokenSupplyInEth - v_.withdrawAmtInEth))) /
                    (10000 - ratios_.stEthLimit);
            } else deleverageAmtTillMinLimit_ = 0;
        }
    }
}
