pragma solidity >=0.5.17 <0.8.4;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";

import "./AggregatorV3Interface.sol";


import "./IStrategy.sol";
import "./IVault.sol";

abstract contract BaseStrategy {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    VaultAPI public vault;

    IERC20 public want;

    // See note on `setEmergencyExit()`.
    bool public emergencyExit;

    uint256 public pricePerShare;
    //    uint256 lastPricePerShare;
    uint256 prevTimestamp;

    uint256 public apy = 0;

    event EmergencyExitEnabled();

    modifier onlyGovernance() {
        require(msg.sender == vault.governance(), '!only governance');
        _;
    }

    modifier onlyVault() {
        require(msg.sender == address(vault), '!only vault');
        _;
    }


    //    modifier onlyKeeper() {
    //        require(vault.isKeeper(msg.sender), '!only keeper');
    //        _;
    //    }

    /**
     * 更新apy
     **/
    function updateApy(uint256 _apy) external onlyVault {
        apy = _apy;
    }



    /**
     * @notice
     *  Activates emergency exit. Once activated, the Strategy will exit its
     *  position upon the next harvest, depositing all funds into the Vault as
     *  quickly as is reasonable given on-chain conditions.
     *
     *  This may only be called by governance or the strategist.
     * @dev
     *  See `vault.setEmergencyShutdown()` and `harvest()` for further details.
     */
    function setEmergencyExit() external onlyGovernance {
        emergencyExit = true;
        //        vault.revokeStrategy();

        emit EmergencyExitEnabled();
    }


    function initialize(address _vault) internal {
        vault = VaultAPI(_vault);
        want = IERC20(vault.token());
        //授权Vault可以无限操作策略中的USDT
        want.safeApprove(_vault, type(uint256).max);
    }

    function protocol() public pure virtual returns (uint256);

    function name() public pure virtual returns (string memory);

    /**
     * 评估总资产
     */
    function estimatedTotalAssets() public view virtual returns (uint256) {
        return pricePerShare.mul(balanceOfLp().div(10 ** lpDecimals()));
    }

    /**
     * 提矿 & 卖出
     * 会产矿的策略需要重写该方法
     * 返回卖矿产生的USDT数
     **/
    function claimAndSellRewards() internal virtual returns (uint256) {
        //子策略需先提矿
        //卖矿换成USDT
        return 0;
    }

    /**
     * correspondingShares：待提取xToken数
     * totalShares：总xToken数
     **/
    function withdrawToVault(uint256 correspondingShares, uint256 totalShares) external onlyVault virtual returns (uint256 value, uint256 partialClaimValue, uint256 claimValue)  {
        //根据correspondingShares/totalShares，计算待提取lpToken数量-withdrawLpTokensCount
        uint256 totalLpCount = balanceOfLp();

        //* 1 ** lpDecimals();
        uint256 withdrawLpTokensCount = totalLpCount.mul(correspondingShares).div(totalShares);

        if (withdrawLpTokensCount > 0) {
            uint256 preTotalAssets = estimatedTotalAssets();
            //从3rd Vault(Pool)中赎回-valueOfLpTokens
            uint256 tokenCount = withdrawSome(withdrawLpTokensCount);

            //兑换成USDT
            uint256 valueOfLpTokens = exchangeToUSDT(tokenCount);

            //提矿卖出
            uint256 totalRewards = claimAndSellRewards();
            uint256 partialRewards = totalRewards.mul(correspondingShares).div(totalShares);

            uint256 lastPricePerShare = pricePerShare;
            //算出单个lpToken的价值：singleValueOfLpToken = (valueOfFarms + valueOfLpTokens)/withdrawLpTokensCount
            pricePerShare = valueOfLpTokens.mul(10 ** lpDecimals()).div(withdrawLpTokensCount);
            if (preTotalAssets > 0 && pricePerShare > lastPricePerShare) {
                //                uint256 deltaOfPricePerShare = pricePerShare - lastPricePerShare;
                //目前apy定义为uint，所以只有差值大于0才更新
                uint256 deltaSeconds = block.timestamp - prevTimestamp;
                uint256 oneYear = 31536000;
                uint256 totalAssets = estimatedTotalAssets() + totalRewards + valueOfLpTokens;


                //                apy = deltaOfPricePerShare.mul(oneYear).div(deltaSeconds).div(lastPricePerShare);
                uint256 deltaOfAssets = totalAssets - preTotalAssets;
                apy = deltaOfAssets.mul(oneYear).mul(1e4).div(deltaSeconds).div(preTotalAssets);

            }

            //将用户赎回份额的USDT转给Vault
            want.safeTransfer(address(vault), totalRewards + valueOfLpTokens);
            prevTimestamp = block.timestamp;


            return (valueOfLpTokens, partialRewards, totalRewards);
        }
        return (0, 0, 0);
    }

    /**
     * 无人提取时，通过调用该方法计算策略净值
     **/
    function withdrawOneToken() external onlyVault virtual returns (uint256 value, uint256 partialClaimValue, uint256 claimValue) {
        uint256 totalLpCount = balanceOfLp();
        if (totalLpCount >= 10 ** uint256(lpDecimals())) {
            uint256 tokenCount = withdrawSome(10 ** uint256(lpDecimals()));
            //兑换成USDT
            uint256 valueOfLpTokens = exchangeToUSDT(tokenCount);

            //提矿卖出
            uint256 totalRewards = claimAndSellRewards();


            //算出单个lpToken的价值：singleValueOfLpToken = (valueOfFarms + valueOfLpTokens)/withdrawLpTokensCount
            pricePerShare = valueOfLpTokens;

            want.safeTransfer(address(vault), valueOfLpTokens + totalRewards);
            //按比例从提矿收益中算出一份lpToken对应的价值-partialRewards
            uint256 oneOfRewards = totalRewards.mul(10 ** uint256(lpDecimals())).div(balanceOfLp());

            return (valueOfLpTokens, oneOfRewards, totalRewards);
        }
        return (0, 0, 0);
    }

    /**
     * 退回超出部分金额
     **/
    function cutOffPosition(uint256 _debtOutstanding) external virtual returns (uint256);

    /**
     * 将空置资金进行投资
     **/
    function invest() public onlyVault {
        uint256 beforeInvest = balanceOfLp();
        uint256 wantBalance = want.balanceOf(address(this));
        investInner();
        uint256 afterInvest = balanceOfLp();
        if (beforeInvest == 0 && afterInvest > 0) {
            pricePerShare = wantBalance.mul(10 ** lpDecimals()).div(afterInvest);
            prevTimestamp = block.timestamp;

        }
    }

    function investInner() internal virtual;

    //策略迁移
    function migrate(address _newStrategy) external virtual;

    //查看策略投资池子的总数量（priced in want）
    function getInvestVaultAssets() external view virtual returns (uint256);

    /**
     * lpToken份额
     **/
    function balanceOfLp() internal view virtual returns (uint256);

    /**
     * lpToken精度
     **/
    function lpDecimals() internal view virtual returns (uint256);

    //    /**
    //    * 矿币精度
    //    **/
    //    function rewardDecimals() internal virtual view returns (uint256);

    /**
     * 从Vault(Pool)中赎回部分
     **/
    function withdrawSome(uint256 shares) internal virtual returns (uint256);

    /**
     * 将中间代币转换成USDT，如EURScrv转成USDT
     * step1：通过curve将EURScrv转成EURS
     * step2：通过DEX将EURS换成USDT
     * return: USDT数量
     **/
    function exchangeToUSDT(uint256 tokenCount) internal virtual returns (uint256);
}
