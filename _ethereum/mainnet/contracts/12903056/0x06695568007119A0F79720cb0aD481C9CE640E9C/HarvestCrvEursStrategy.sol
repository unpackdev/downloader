pragma solidity >=0.5.17 <0.8.4;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./SafeCast.sol";
import "./Math.sol";



import "./BaseStrategy.sol";
import "./ProtocolEnum.sol";
import "./HarvestVault.sol";
import "./HarvestStakePool.sol";
import "./EthPriceFeed.sol";
import "./IUniswapV2.sol";
import "./IUniswapV3.sol";
import "./ICurveFi.sol";
//import "./Sushi.sol";
import "./SwapFarm2EursInUniswapV2.sol";

contract HarvestCrvEursStrategy is BaseStrategy, SwapFarm2EursInUniswapV2 {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    //投资crvEURS对应的金库，返回FARM_eursCRV (feursCRV)
    address public constant fVault = address(0x6eb941BD065b8a5bd699C5405A928c1f561e2e5a);
    //crvEURS二次抵押对应的池子
    address public constant fPool = address(0xf4d50f60D53a230abc8268c6697972CB255Cd940);
    //FARM币
    address public rewardToken = address(0xa0246c9032bC3A600820415aE600c6388619A14D);
    address constant EURS = address(0xdB25f211AB05b1c97D595516F45794528a807ad8);
    IERC20 sEURToken = IERC20(0xD71eCFF9342A5Ced620049e616c5035F1dB98620);
    IERC20 constant baseToken = IERC20(0x194eBd173F6cDacE046C53eACcE9B953F28411d1);
    // the address of the Curve protocol's pool for EURS and sEUR
    address public curveAddress = address(0x0Ce6a5fF5217e38315f87032CF90686C96627CAA);
    // 8位精度结果。其他汇率兑换：Ethereum Price Feeds https://docs.chain.link/docs/ethereum-addresses/
    address public EUR_USD = address(0xb49f677943BC038e9857d61E7d053CaA2C1734C1);

    //uni v2 address
    address constant uniV2Address = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    //WETH
    address constant WETH = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    //USDC
    address constant USDC = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    //curve eurs pool address
    address constant curvePool = address(0x0Ce6a5fF5217e38315f87032CF90686C96627CAA);
    //sushi address
    address constant sushiAddress = address(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);

    //上次doHardwork按币本位计价的资产总值
    uint256 internal lastTotalAssets = 0;
    //当日赎回
    uint256 internal dailyWithdrawAmount = 0;

    constructor(address _vault) public {
        address[] memory tokens = new address[](1);
        tokens[0] = address(baseToken);
//        tokens[1] = address(sEURToken);
        initialize('HarvestCrvEursStrategy', uint16(ProtocolEnum.Harvest), _vault, tokens);
    }

    function _getExchangePrice(address pairProxyAddress) internal view returns (int) {
        (uint80 roundID,int price,uint startedAt,uint timeStamp,uint80 answeredInRound) = AggregatorV3Interface(pairProxyAddress).latestRoundData();
        return price;
    }

    /**
     * 计算基础币(USDT)与其它币种的数量关系，
     * sEUR没有汇率，暂时与ERUS比例为1:1
     * 如该池是CrvUSDN池，underlying是USDT数量，返回的则是EURS和sEUR的数量
     * @param amountUnderlying 需要投资USDT数量
     **/
    function calculate(uint256 amountUnderlying) external view override returns (uint256[] memory, uint256[] memory) {
        require(amountUnderlying > 0, 'amountUnderlying<=0');
        //一个单位ERU换几个单位USD
        int256 price = _getExchangePrice(EUR_USD);
        uint256 curveVirtualPrice = ICurveFi(curveAddress).get_virtual_price();
        uint256[] memory coinsAmount = new uint256[](1);
        coinsAmount[0] = amountUnderlying.mul(1e20).div(uint(price)).mul(1e18).div(curveVirtualPrice);
        uint256[] memory underlyingAmount = new uint256[](1);
        underlyingAmount[0] = amountUnderlying;

        return (coinsAmount,underlyingAmount);
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
        ( uint256[] memory coinsAmount,) = this.calculate(amountUnderlying);
        uint256 needCrvEurs = coinsAmount[0];

        uint256 balance = baseToken.balanceOf(address(this));
        if (balance >= needCrvEurs){
            baseToken.transfer(address(vault),needCrvEurs);
        } else {
            uint256 missAmount = needCrvEurs - balance;
            uint256 shares = missAmount
                                .mul(10 ** IERC20Metadata(fVault).decimals())
                                .div(HarvestVault(fVault).getPricePerFullShare());


            if (shares > 0){

                shares = Math.min(shares,HarvestStakePool(fPool).balanceOf(address(this)));
                HarvestStakePool(fPool).withdraw(shares);
                HarvestVault(fVault).withdraw(shares);
                uint256 withdrawAmount = baseToken.balanceOf(address(this));

                baseToken.safeTransfer(address(vault),withdrawAmount);

                dailyWithdrawAmount += withdrawAmount;


            }
        }

    }

    /**
     * 第三方池的净值,单个yToken的价格(USDN)
     **/
    function getPricePerFullShare() external view override returns (uint256) {
        return HarvestVault(fVault).getPricePerFullShare();
    }

    /**
     * 已经投资的underlying数量，策略实际投入的是不同的稳定币，这里涉及待投稳定币与underlying之间的换算
     **/
    function investedUnderlyingBalance() external view override returns (uint256) {
        uint256 stakingAmount = HarvestStakePool(fPool).balanceOf(address(this));
        uint256 balance = baseToken.balanceOf(address(this));
        uint256 crvEURSAmount = stakingAmount.mul(HarvestVault(fVault).getPricePerFullShare()).div(10 ** IERC20Metadata(fVault).decimals()).add(balance);
        int256 price = _getExchangePrice(EUR_USD);
        uint256 curveVirtualPrice = ICurveFi(curveAddress).get_virtual_price();
        return crvEURSAmount
                .mul(curveVirtualPrice)
                .div(1e18)
                .mul(uint(price))
                .div(1e8)
                .div(10 ** (IERC20Metadata(fVault).decimals() - 6));
    }

    /**
     * 查看策略投资池子的总数量（priced in want）
     **/
    function getInvestVaultAssets() external view override returns (uint256) {
        int256 price = _getExchangePrice(EUR_USD);
        uint256 curveVirtualPrice = ICurveFi(curveAddress).get_virtual_price();
        uint256 crvEURSAmount = HarvestVault(fVault).getPricePerFullShare()
                                    .mul(IERC20(fVault).totalSupply())
                                    .div(10 ** IERC20Metadata(fVault).decimals());
        return crvEURSAmount.mul(curveVirtualPrice)
                .div(1e18)
                .mul(uint(price))
                .div(1e8)
                .div(10 ** (IERC20Metadata(fVault).decimals() - 6));
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
        //Farm swap to WETH from UniV2
        address[] memory path = new address[](2);
        path[0] = rewardToken;
        path[1] = USDC;
        IERC20(rewardToken).approve(uniV2Address,0);
        IERC20(rewardToken).approve(uniV2Address,amount);

        // 矿币达到一定数量后，才去兑换，要不然会存在返回为0的情况。
        if(amount > 10**15){
            swapFarm2EursInUniswapV2(amount,0,1800);
            uint256 eursBalance = IERC20(EURS).balanceOf(address(this));

            IERC20(EURS).safeApprove(curvePool,0);
            IERC20(EURS).safeApprove(curvePool,eursBalance);
            ICurveFi(curvePool).add_liquidity([eursBalance, 0], 0);
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

            int assetsDelta = int(totalAssets + dailyWithdrawAmount + _rewards - lastTotalAssets);
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
    function migrate(address _newStrategy) external override {}
}
