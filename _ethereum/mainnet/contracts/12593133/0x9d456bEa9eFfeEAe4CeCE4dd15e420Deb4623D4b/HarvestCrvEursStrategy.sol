pragma solidity >=0.5.17 <0.8.4;

import "./IERC20.sol";
import "./Address.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";



import "./BaseStrategy.sol";
import "./HarvestVault.sol";
import "./HarvestStakePool.sol";
import "./ITransfers.sol";
import "./Transfers.sol";
import "./ICurveEURSDeposit.sol";
import "./AggregatorV3Interface.sol";
import "./ProtocolEnum.sol";

/**

 **/
contract HarvestCrvEursStrategy is BaseStrategy, Transfers {
    using SafeERC20 for IERC20;
    using SafeERC20 for ERC20;
    using SafeMath for uint256;
    //crvEURS对应的金库
    address public fVault = address(0x6eb941BD065b8a5bd699C5405A928c1f561e2e5a);
    //crvEURS二次抵押对应的池子
    address public fPool = address(0xf4d50f60D53a230abc8268c6697972CB255Cd940);
    //FARM币
    IERC20 public rewardToken = IERC20(0xa0246c9032bC3A600820415aE600c6388619A14D);
    ERC20 public eursToken = ERC20(0xdB25f211AB05b1c97D595516F45794528a807ad8);
    ERC20 public eursCRVToken = ERC20(0x194eBd173F6cDacE046C53eACcE9B953F28411d1);
    // the address of the Curve protocol's pool for EURS and sEUR
    address public curveAddress = address(0x0Ce6a5fF5217e38315f87032CF90686C96627CAA);
    // 8位精度结果。其他汇率兑换：Ethereum Price Feeds https://docs.chain.link/docs/ethereum-addresses/
    address public EUR_USD = address(0xb49f677943BC038e9857d61E7d053CaA2C1734C1);

    constructor(address _vault) public {
        initialize(_vault);
    }

    /**
     * 对应的协议 0表示harvest,1表示yearn
     **/
    function protocol() public pure override returns (uint256) {
        return uint256(ProtocolEnum.Harvest);
    }

    function name() public pure override returns (string memory) {
        return 'HarvestCrvEursStrategy';
    }

    /**
     * lpToken份额
     **/
    function balanceOfLp() internal view override returns (uint256) {
        return HarvestStakePool(fPool).balanceOf(address(this));
    }

    /**
     * lpToken精度
     **/
    function lpDecimals() internal view override returns (uint256) {
        return HarvestVault(fVault).decimals();
    }

    /**
     * 提矿 & 卖出
     * 会产矿的策略需要重写该方法
     * 返回卖矿产生的USDT数
     **/
    function claimAndSellRewards() internal override returns (uint256) {
        //子策略需先提矿
        HarvestStakePool(fPool).getReward();
        //把提到的FARM币换成USDT
        uint256 amount = rewardToken.balanceOf(address(this));
        if (amount > 0) {
            uint256 balanceBefore = want.balanceOf(address(this));
            swap(address(rewardToken), address(want), amount, 0);
            uint256 balanceAfter = want.balanceOf(address(this));
            return balanceAfter - balanceBefore;
        }

        return 0;
    }

    /**
     * 从pool中赎回fToken,再用fToken取回eursCRV
     * @param shares 要提取的最终token的数量，这里是fToken币的数量
     * @return eursCRV币的数量
     **/
    function withdrawSome(uint256 shares) internal override returns (uint256) {
        if (shares > 0) {
            //从挖矿池中赎回
            HarvestStakePool(fPool).withdraw(shares);
            //从fVault中赎回
            HarvestVault(fVault).withdraw(shares);
            uint256 amount = eursCRVToken.balanceOf(address(this));
            return amount;
        } else {
            return 0;
        }
    }

    /**
     * //TODO 尽量按照Harvest和Yearn代码来，别封装后更不可读，例如下面的ITransfers
     * 将中间代币转换成USDT，本处：eursCRV转成USDT
     * step1：通过curve将eursCRV转成EURS
     * step2：通过DEX将EURS换成USDT
     * @param tokenCount 要提取harvest里面转出来的币的数量，这里是eursCRV 的数量
     * return: USDT数量
     **/
    function exchangeToUSDT(uint256 tokenCount) internal override returns (uint256) {

        //eursCRV转成EURS
        //TODO 该方法参数需要明确什么含义，特别是第3个参数
        ICurveEURSDeposit(curveAddress).remove_liquidity_one_coin(tokenCount, 0, 0);

        //EURS转成USDT
        uint256 eursBalance = eursToken.balanceOf(address(this));
        (uint80 roundID, int256 price, uint256 startedAt, uint256 timeStamp, uint80 answeredInRound) =
            AggregatorV3Interface(EUR_USD).latestRoundData();
        uint256 percent = 1e4 - vault.maxExchangeRateDeltaThreshold();

        uint256 miniReturn = eursBalance.mul(uint256(price).mul(percent)).div(1e9);
        uint256 returnUSDT = swap(address(eursToken), address(want), eursBalance, miniReturn);
        //返回USDT token数量
        return returnUSDT;
    }

    /**
     * 当前策略投资超额的时候，vault会调用该方法，返回超额部分的USDT给vault
     **/
    function cutOffPosition(uint256 _debtOutstanding) external override onlyVault returns (uint256) {

        //需要返还vault的USDT数量
        if (_debtOutstanding > 0) {
            uint256 _balance = want.balanceOf(address(this));
            if (_debtOutstanding <= _balance) {
                //返回给金库
                want.safeTransfer(address(vault), _debtOutstanding);
                return _debtOutstanding;
            } else {
                //还差的USDT数量
                uint256 missAmount = _debtOutstanding - _balance;
                //还需要LPToken的数量
                uint256 needLpAmount = 0;
                uint256 allAssets = estimatedTotalAssets();
                if (missAmount >= allAssets) {
                    needLpAmount = balanceOfLp();
                } else {
                    //需要解包提取的数量,按百分比提取
                    needLpAmount = missAmount.mul(balanceOfLp()).div(allAssets);
                }

                uint256 eursCRVAmount = withdrawSome(needLpAmount);
                uint256 usdtAmount = exchangeToUSDT(eursCRVAmount);
                //将余额和解包出来的USDT返回金库
                uint256 returnDebt = usdtAmount + _balance;
                want.safeTransfer(address(vault), returnDebt);
                return returnDebt;
            }
        }
        return 0;
    }

    /**
     * 将空置资金进行投资
     **/
    function investInner() internal override {
        uint256 usdtBalance = want.balanceOf(address(this));

        if (usdtBalance > 0) {
            (uint80 roundID, int256 price, uint256 startedAt, uint256 timeStamp, uint80 answeredInRound) =
                AggregatorV3Interface(EUR_USD).latestRoundData();
            uint256 expectReturn = usdtBalance.mul(1e8).div(uint256(price));
            uint256 percent = 1e4 - vault.maxExchangeRateDeltaThreshold();

            //最小返回数，price精度为1e8,(usdt / price) * (1e9 - threshold) / (1**(9 - 8 + 4))
            uint256 miniReturn = usdtBalance.mul(percent).div(uint256(price)).div(10);
            uint256 eursAmount = swap(address(want), address(eursToken), usdtBalance, miniReturn);
        }
        uint256 eursBalance = eursToken.balanceOf(address(this));

        if (eursBalance > 0) {
            eursToken.safeApprove(curveAddress, 0);
            eursToken.safeApprove(curveAddress, eursBalance);
            ICurveEURSDeposit(curveAddress).add_liquidity([eursBalance, 0], 0);
        }
        uint256 eursCRVBalance = eursCRVToken.balanceOf(address(this));

        if (eursCRVBalance > 0) {
            eursCRVToken.safeApprove(fVault, 0);
            eursCRVToken.safeApprove(fVault, eursCRVBalance);
            HarvestVault(fVault).deposit(eursCRVBalance);
        }

        //二次抵押
        uint256 fTokenBalance = IERC20(fVault).balanceOf(address(this));

        if (fTokenBalance > 0) {
            IERC20(fVault).safeApprove(fPool, 0);
            IERC20(fVault).safeApprove(fPool, fTokenBalance);
            HarvestStakePool(fPool).stake(fTokenBalance);
        }

    }

    /**
     * 计算第三方池子的当前总资金
     **/
    function getInvestVaultAssets() external view override returns (uint256) {
        uint256 eursCRVBalance = HarvestVault(fVault).underlyingBalanceWithInvestment();
        // eurs的余额：eursCRV的余额/精度*（每个eursCRV的虚拟价格/虚拟价格的精度）*eurs的精度
        // 虚拟价格的精度1e18，curve合约未继承ERC20，但代码中配置了精度1e18
        uint256 eursBalance = eursCRVBalance.div(10 ** eursCRVToken.decimals())
        .mul(ICurveEURSDeposit(curveAddress).get_virtual_price()).div(1e18)
        .mul(10 ** eursToken.decimals());
        (uint80 roundID, int256 price, uint256 startedAt, uint256 timeStamp, uint80 answeredInRound) = AggregatorV3Interface(EUR_USD).latestRoundData();
        //用预言机的汇率来转换,当前是用现实中的欧元和美元汇率
        uint256 totalAsset = eursBalance.mul(uint256(price)).div(10**4);

        return totalAsset;
    }

    function migrate(address _newStrategy) external override {}
}
