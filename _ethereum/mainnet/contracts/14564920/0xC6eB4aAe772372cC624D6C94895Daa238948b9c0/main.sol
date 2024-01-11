//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./helpers.sol";
import "./IERC20.sol";

contract InstaVaultResolver is Helpers {

    struct VaultInfo {
        address token;
        uint8 decimals;
        uint256 tokenMinLimit;
        address atoken;
        address vaultDsa;
        VaultInterface.Ratios ratios;
        uint256 exchangePrice;
        uint256 lastRevenueExchangePrice;
        uint256 revenueFee;
        uint256 revenue;
        uint256 revenueEth;
        uint256 withdrawalFee;
        uint256 idealExcessAmt;
        uint256 swapFee;
        uint256 saveSlippage;
        uint256 vTokenTotalSupply;
        uint256 tokenCollateralAmt_;
        uint256 tokenVaultBal_;
        uint256 tokenDSABal_;
        uint256 netTokenBal_;
        uint256 stethCollateralAmt_;
        uint256 stethVaultBal_;
        uint256 stethDSABal_;
        uint256 wethDebtAmt_;
        uint256 wethVaultBal_;
        uint256 wethDSABal_;
    }

    function getVaultInfo(address vaultAddr_)
        public
        view
        returns (VaultInfo memory vaultInfo_)
    {
        VaultInterface vault = VaultInterface(vaultAddr_);
        vaultInfo_.token = vault.token();
        vaultInfo_.decimals = vault.decimals();
        vaultInfo_.tokenMinLimit = vault.tokenMinLimit();
        vaultInfo_.atoken = vault.atoken();
        vaultInfo_.vaultDsa = vault.vaultDsa();
        vaultInfo_.ratios = vault.ratios();
        (vaultInfo_.exchangePrice, ) = vault.getCurrentExchangePrice();
        vaultInfo_.lastRevenueExchangePrice = vault.lastRevenueExchangePrice();
        vaultInfo_.revenueFee = vault.revenueFee();
        vaultInfo_.revenue = vault.revenue();
        vaultInfo_.revenueEth = vault.revenueEth();
        vaultInfo_.withdrawalFee = vault.withdrawalFee();
        vaultInfo_.idealExcessAmt = vault.idealExcessAmt();
        vaultInfo_.swapFee = vault.swapFee();
        vaultInfo_.saveSlippage = vault.saveSlippage();
        vaultInfo_.vTokenTotalSupply = vault.totalSupply();
        (vaultInfo_.tokenCollateralAmt_, vaultInfo_.stethCollateralAmt_, vaultInfo_.wethDebtAmt_, vaultInfo_.tokenVaultBal_, vaultInfo_.tokenDSABal_, vaultInfo_.netTokenBal_) = vault.getVaultBalances();
        vaultInfo_.stethVaultBal_ = IERC20(stEthAddr).balanceOf(vaultAddr_);
        vaultInfo_.stethDSABal_ = IERC20(stEthAddr).balanceOf(vaultInfo_.vaultDsa);
        vaultInfo_.wethVaultBal_ = IERC20(wethAddr).balanceOf(vaultAddr_);
        vaultInfo_.wethDSABal_ = IERC20(wethAddr).balanceOf(vaultInfo_.vaultDsa);
    }

    struct UserInfo {
        address vaultAddr;
        VaultInfo vaultInfo;
        uint256 vtokenBal;
        uint256 amount;
    }

    function getUserInfo(address[] memory vaults_, address user_)
        public
        view
        returns (UserInfo[] memory userInfos_)
    {
        userInfos_ = new UserInfo[](vaults_.length);
        for (uint i = 0; i < vaults_.length; i++) {
            VaultInterface vault = VaultInterface(vaults_[i]);
            userInfos_[i].vaultInfo = getVaultInfo(vaults_[i]);
            userInfos_[i].vtokenBal = vault.balanceOf(user_);
            userInfos_[i].amount = (userInfos_[i].vtokenBal * userInfos_[i].vaultInfo.exchangePrice) / 1e18;
        }
    }

    function collectProfitData(address vaultAddr_, bool isWeth_) public view returns (uint256 withdrawAmt_, uint256 amt_) {
        VaultInterface vault = VaultInterface(vaultAddr_);
        uint256 profits_ = (vault.getNewProfits() * 99) / 100; // keeping 1% margin
        uint256 vaultBal_;
        if (isWeth_) vaultBal_ = IERC20(wethAddr).balanceOf(vaultAddr_);
        else vaultBal_ = IERC20(stEthAddr).balanceOf(vaultAddr_);

        (,uint stethCollateralAmt_,,,,) = vault.getVaultBalances();
        if (profits_ <= vaultBal_) {
            withdrawAmt_ = 0;
        } else {
            uint maxAmt_ = (stethCollateralAmt_ * vault.idealExcessAmt()) / 10000;
            maxAmt_ = (maxAmt_ * 99) / 100; // keeping 1% margin
            withdrawAmt_ = maxAmt_ + profits_ - vaultBal_;
        }
        amt_ = profits_;
    }

    struct RebalanceOneVariables {
        address tokenAddr;
        uint256 tokenDecimals;
        uint256 tokenMinLimit;
        uint256 tokenVaultBal;
        uint256 netTokenBal;
        VaultInterface.Ratios ratios;
        uint256 stethCollateral;
        uint256 wethDebt;
        uint256 ethCoveringDebt;
        uint256 excessDebt;
        uint256 tokenPriceInEth;
        uint netTokenSupplyInEth;
        uint256 currentRatioMin;
        uint256[] deleverageAmts;
    }

    function rebalanceOneData(address vaultAddr_, address[] memory vaultsToCheck_)
        public
        view 
        returns (
            address flashTkn_, // currently its always weth addr
            uint256 flashAmt_,
            uint256 route_,
            address[] memory vaults_,
            uint256[] memory amts_,
            uint256 leverageAmt_,
            uint256 swapAmt_,
            uint256 tokenSupplyAmt_,
            uint256 tokenWithdrawAmt_ // currently always returned zero
        ) 
    {
        RebalanceOneVariables memory v_;
        VaultInterface vault_ = VaultInterface(vaultAddr_);
        v_.tokenAddr = vault_.token();
        v_.tokenDecimals = vault_.decimals();
        v_.tokenMinLimit = vault_.tokenMinLimit();
        (, v_.stethCollateral, v_.wethDebt, v_.tokenVaultBal,, v_.netTokenBal) = vault_.getVaultBalances();
        if (v_.tokenVaultBal > v_.tokenMinLimit) tokenSupplyAmt_ = v_.tokenVaultBal;
        v_.ratios = vault_.ratios();
        v_.ethCoveringDebt = (v_.stethCollateral * v_.ratios.stEthLimit) / 10000;
        v_.excessDebt = v_.ethCoveringDebt < v_.wethDebt ? v_.wethDebt - v_.ethCoveringDebt : 0;
        v_.tokenPriceInEth = IAavePriceOracle(aaveAddressProvider.getPriceOracle()).getAssetPrice(v_.tokenAddr);
        v_.netTokenSupplyInEth = (v_.netTokenBal * v_.tokenPriceInEth) / (10 ** v_.tokenDecimals);
        v_.currentRatioMin = v_.netTokenSupplyInEth == 0 ? 0 : (v_.excessDebt * 10000) / v_.netTokenSupplyInEth;
        if (v_.currentRatioMin < v_.ratios.minLimitGap) {
            // keeping 0.1% margin for final ratio
            leverageAmt_ = (((v_.ratios.minLimit - 10) - v_.currentRatioMin) * v_.netTokenSupplyInEth) / (10000 - v_.ratios.stEthLimit);
            flashTkn_ = wethAddr;
            // TODO: dont take flashloan if not needed
            flashAmt_ = (v_.netTokenSupplyInEth / 10) + (leverageAmt_ * 10 / 8); // 10% of current collateral(in eth) + leverageAmt_ / 0.8
            route_ = 5;
            v_.deleverageAmts = getMaxDeleverageAmts(vaultsToCheck_);
            (vaults_, amts_, swapAmt_) = getVaultsToUse(vaultsToCheck_, v_.deleverageAmts, leverageAmt_);
        }
    }

    struct RebalanceTwoVariables {
        address tokenAddr;
        uint256 tokenDecimals;
        uint256 tokenMinLimit;
        uint256 stethCollateral;
        uint256 wethDebt;
        uint256 tokenVaultBal;
        uint256 netTokenBal;
        VaultInterface.Ratios ratios;
        uint256 ethCoveringDebt;
        uint256 excessDebt;
        uint256 tokenPriceInEth;
        uint netTokenCollateralInEth;
        uint256 currentRatioMax;
    }

    function rebalanceTwoData(address vaultAddr_)
        public
        view
        returns (
            address flashTkn_,
            uint256 flashAmt_,
            uint256 route_,
            uint256 saveAmt_,
            uint256 tokenSupplyAmt_
        )
    {
        VaultInterface vault_ = VaultInterface(vaultAddr_);
        RebalanceTwoVariables memory v_;
        v_.tokenAddr = vault_.token();
        v_.tokenDecimals = vault_.decimals();
        v_.tokenMinLimit = vault_.tokenMinLimit();
        (, v_.stethCollateral, v_.wethDebt, v_.tokenVaultBal,, v_.netTokenBal) = vault_.getVaultBalances();
        if (v_.tokenVaultBal > v_.tokenMinLimit) tokenSupplyAmt_ = v_.tokenVaultBal;
        VaultInterface.Ratios memory ratios_ = vault_.ratios();
        v_.ethCoveringDebt = (v_.stethCollateral * ratios_.stEthLimit) / 10000;
        v_.excessDebt = v_.ethCoveringDebt < v_.wethDebt ? v_.wethDebt - v_.ethCoveringDebt : 0;
        v_.tokenPriceInEth = IAavePriceOracle(aaveAddressProvider.getPriceOracle()).getAssetPrice(v_.tokenAddr);
        v_.netTokenCollateralInEth = (v_.netTokenBal * v_.tokenPriceInEth) / (10 ** v_.tokenDecimals);
        v_.currentRatioMax = v_.netTokenCollateralInEth == 0 ? 0 : (v_.excessDebt * 10000) / v_.netTokenCollateralInEth;
        if (v_.currentRatioMax > ratios_.maxLimit) {
            saveAmt_ = ((v_.currentRatioMax - (ratios_.maxLimitGap + 10)) * v_.netTokenCollateralInEth) / (10000 - ratios_.stEthLimit);
            flashTkn_ = wethAddr;
            // TODO: dont take flashloan if not needed
            flashAmt_ = (v_.netTokenCollateralInEth / 10) + (saveAmt_ * 10 / 8); // 10% of current collateral(in eth) + (leverageAmt_ / 0.8)
            route_ = 5;
        }
    }
}
