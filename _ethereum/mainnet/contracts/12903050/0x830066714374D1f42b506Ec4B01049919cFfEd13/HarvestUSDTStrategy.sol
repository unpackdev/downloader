pragma solidity >=0.5.17 <0.8.4;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Math.sol";



import "./BaseStrategy.sol";
import "./ProtocolEnum.sol";
import "./HarvestVault.sol";
import "./HarvestStakePool.sol";
import "./IUniswapV2.sol";
//import "./ICurveFi.sol";
import "./Sushi.sol";
import "./SwapFarm2UsdtInUniswapV2.sol";

contract HarvestUSDTStrategy is BaseStrategy, SwapFarm2UsdtInUniswapV2{

    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    //待投的币种
    IERC20 public constant baseToken = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    //待投池地址
    address public fVault = address(0x053c80eA73Dc6941F518a68E2FC52Ac45BDE7c9C);
    //质押池地址
    address public fPool = address(0x6ac4a7AB91E6fD098E13B7d347c6d4d1494994a2);
    //Farm Token
    address public rewardToken = address(0xa0246c9032bC3A600820415aE600c6388619A14D);
    //uni v2 address
    address constant uniV2Address = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    //WETH
    address constant WETH = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    //curve pool address
    address constant curvePool = address(0x80466c64868E1ab14a1Ddf27A676C3fcBE638Fe5);
    //sushi address
    address constant sushiAddress = address(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);

    //上次doHardwork按币本位计价的资产总值
    uint256 internal lastTotalAssets = 0;
    //当日赎回
    uint256 internal dailyWithdrawAmount = 0;

    constructor(address _vault){
        address[] memory tokens = new address[](1);
        tokens[0] = address(baseToken);
        initialize("HarvestUSDTStrategy",
                   uint16(ProtocolEnum.Harvest),
                   _vault,
                   tokens);
    }

    /**
   * 计算基础币与其它币种的数量关系
   * 如该池是CrvEURS池，underlying是USDT数量，返回的则是 EURS、SEUR的数量
   **/
    function calculate(uint256 amountUnderlying) external override view returns (uint256[] memory,uint256[] memory){
        uint256[] memory tokenAmountArr = new uint256[](1);
        tokenAmountArr[0] = amountUnderlying;
        return (tokenAmountArr, tokenAmountArr);
    }

    function withdrawAllToVault() external onlyVault override {
        uint stakingAmount = HarvestStakePool(fPool).balanceOf(address(this));
        if (stakingAmount > 0){
            _claimRewards();
            HarvestStakePool(fPool).withdraw(stakingAmount);
            HarvestVault(fVault).withdraw(stakingAmount);
        }
        uint256 withdrawAmount = baseToken.balanceOf(address(this));
        if (withdrawAmount > 0){
            baseToken.safeTransfer(address(vault),withdrawAmount);
            dailyWithdrawAmount += withdrawAmount;
        }
    }

    /**
    * amountUnderlying:需要的基础代币数量
    **/
    function withdrawToVault(uint256 amountUnderlying) external onlyVault override {
        uint256 balance = baseToken.balanceOf(address(this));
        if (balance >= amountUnderlying){
            baseToken.safeTransfer(address(vault),amountUnderlying);
        } else {
            uint256 missAmount = amountUnderlying - balance;
            uint256 shares = missAmount.mul(10 ** HarvestVault(fVault).decimals()).div(HarvestVault(fVault).getPricePerFullShare());
            if (shares > 0){
                uint256 stakeAmount = HarvestStakePool(fPool).balanceOf(address(this));
                shares = Math.min(shares,stakeAmount);

                HarvestStakePool(fPool).withdraw(shares);
                HarvestVault(fVault).withdraw(shares);
                uint256 withdrawAmount = baseToken.balanceOf(address(this));
                baseToken.safeTransfer(address(vault),withdrawAmount);

                dailyWithdrawAmount += withdrawAmount;
            }
        }
    }


    /**
    * 第三方池的净值
    **/
    function getPricePerFullShare() external override view returns (uint256) {
        return HarvestVault(fVault).getPricePerFullShare();
    }

    /**
    * 已经投资的underlying数量，策略实际投入的是不同的稳定币，这里涉及待投稳定币与underlying之间的换算
    **/
    function investedUnderlyingBalance() external override view returns (uint256) {
        uint stakingAmount = HarvestStakePool(fPool).balanceOf(address(this));
        uint baseTokenBalance = baseToken.balanceOf(address(this));
        uint prs = HarvestVault(fVault).getPricePerFullShare();
        return stakingAmount
                .mul(prs)
                .div(10 ** IERC20Metadata(fVault).decimals())
                .add(baseTokenBalance);
    }

    /**
    * 查看策略投资池子的总数量（priced in want）
    **/
    function getInvestVaultAssets() external override view returns (uint256) {
        return HarvestVault(fVault).getPricePerFullShare()
                .mul(IERC20(fVault).totalSupply())
                .div(10 ** IERC20Metadata(fVault).decimals());
    }


    /**
    * 针对策略的作业：
    * 1.提矿 & 换币（矿币换成策略所需的稳定币？）
    * 2.计算apy
    * 3.投资
    **/
    function doHardWorkInner() internal override {
        uint256 rewards = 0;
        if (HarvestStakePool(fPool).balanceOf(address(this)) > 0){
            rewards = _claimRewards();
        }
        _updateApy(rewards);
        _invest();
        lastTotalAssets = HarvestStakePool(fPool).balanceOf(address(this))
                            .mul(HarvestVault(fVault).getPricePerFullShare())
                            .div(10 ** IERC20Metadata(fVault).decimals());
        lastDoHardworkTimestamp = block.timestamp;
        dailyWithdrawAmount = 0;
    }

    function _claimRewards() internal returns (uint256) {
        HarvestStakePool(fPool).getReward();
        uint256 amount = IERC20(rewardToken).balanceOf(address(this));

        if (amount == 0){
            return 0;
        }
        //兑换成investToken
        //TODO::当Farm数量大于50时先从uniV2换成ETH然后再从curve换
        uint256 balanceBeforeSwap = IERC20(baseToken).balanceOf(address(this));
        if(amount>10**15){
            swapFarm2UsdtInUniswapV2(amount,0,1800);
            uint256 balanceAfterSwap = IERC20(baseToken).balanceOf(address(this));

            return balanceAfterSwap - balanceBeforeSwap;
        }
        return 0;
    }

    function _updateApy(uint256 _rewards) internal {
        // 第一次投资时lastTotalAssets为0，不用计算apy
        if (lastTotalAssets > 0 && lastDoHardworkTimestamp > 0){
            uint256 totalAssets = HarvestStakePool(fPool).balanceOf(address(this))
                                    .mul(HarvestVault(fVault).getPricePerFullShare())
                                    .div(10 ** IERC20Metadata(fVault).decimals());

            int assetsDelta = int(totalAssets) + int(dailyWithdrawAmount) + int(_rewards) - int(lastTotalAssets);
            calculateProfitRate(lastTotalAssets,assetsDelta);
        }
    }

    function _invest() internal {
        uint256 balance = baseToken.balanceOf(address(this));
        if (balance > 0) {
            baseToken.safeApprove(fVault, 0);
            baseToken.safeApprove(fVault, balance);
            HarvestVault(fVault).deposit(balance);


            //stake
            uint256 lpAmount = IERC20(fVault).balanceOf(address(this));
            IERC20(fVault).safeApprove(fPool, 0);
            IERC20(fVault).safeApprove(fPool, lpAmount);
            HarvestStakePool(fPool).stake(lpAmount);
            lastTotalAssets = HarvestStakePool(fPool).balanceOf(address(this)).mul(HarvestVault(fVault).getPricePerFullShare()).div(10 ** IERC20Metadata(fVault).decimals());
        }
    }



    /**
    * 策略迁移
    **/
    function migrate(address _newStrategy) external override {

    }
}
