pragma solidity >=0.5.17 <0.8.4;

import "./IERC20.sol";
import "./Address.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";



import "./BaseStrategy.sol";
import "./HarvestVault.sol";
import "./HarvestStakePool.sol";
import "./Transfers.sol";
import "./ProtocolEnum.sol";

contract HarvestUSDTStrategy is BaseStrategy, Transfers {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    address public fVault = address(0x053c80eA73Dc6941F518a68E2FC52Ac45BDE7c9C);
    address public fPool = address(0x6ac4a7AB91E6fD098E13B7d347c6d4d1494994a2);
    address public rewardToken = address(0xa0246c9032bC3A600820415aE600c6388619A14D);
    address public transfer;

    constructor(address _vault) public {
        initialize(_vault);
    }

    function protocol() public pure override returns (uint256) {
        return uint256(ProtocolEnum.Harvest);
    }

    function name() public pure override returns (string memory) {
        return 'HarvestUSDTStrategy';
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
     * 从Vault(Pool)中赎回部分
     **/
    function withdrawSome(uint256 shares) internal override returns (uint256) {
        require(shares > 0, "must large than 0");
        //从挖矿池中赎回
        HarvestStakePool(fPool).withdraw(shares);
        //从fVault中赎回
        HarvestVault(fVault).withdraw(shares);
        uint256 amount = want.balanceOf(address(this));
        //shares * IYearnVaultV1(fVault).getPricePerFullShare() / 1e18;
        return amount;
    }

    /**
     * 将中间代币转换成USDT，如EURScrv转成USDT
     * step1：通过curve将EURScrv转成EURS
     * step2：通过DEX将EURS换成USDT
     * return: USDT数量
     **/
    function exchangeToUSDT(uint256 tokenCount) internal override returns (uint256) {
        //这里中间币本来就是USDT，不用转换
        return tokenCount;
    }

    /**
     * 提矿 & 卖出
     * 会产矿的策略需要重写该方法
     * 返回卖矿产生的USDT数
     **/
    function claimAndSellRewards() internal override returns (uint256) {
        //子策略需先提矿
        HarvestStakePool(fPool).getReward();
        //TODO::卖矿换成USDT
        uint256 amount = IERC20(rewardToken).balanceOf(address(this));

        if (amount > 0) {
            uint256 balanceBefore = want.balanceOf(address(this));
            swap(rewardToken, address(want), amount,0);
            uint256 balanceAfter = want.balanceOf(address(this));
            return balanceAfter - balanceBefore;
        }

        return 0;
    }

    /**
     * 退回超出部分金额
     **/
    function cutOffPosition(uint256 _debtOutstanding) external onlyVault override returns (uint256){
        if (_debtOutstanding > 0) {
            uint256 _balance = want.balanceOf(address(this));
            if (_debtOutstanding > _balance) {
                uint256 totalAssets = estimatedTotalAssets();

                if (_debtOutstanding > totalAssets) {
                    //全部赎回
                    HarvestStakePool(fPool).exit();
                    HarvestVault(fVault).withdrawAll();
                    //TODO::这里可能产生了一些损失导致赎回时金额不够
                } else {
                    uint256 needShares =
                    (_debtOutstanding - _balance).mul(10 ** lpDecimals()).div(HarvestVault(fVault).getPricePerFullShare());

                    if (needShares > 0) {
                        withdrawSome(needShares);
                    }
                }
                uint256 returnDebt = want.balanceOf(address(this));
                // 将余额转给Vault
                want.safeTransfer(address(vault), returnDebt);
                return returnDebt;
            } else {
                want.safeTransfer(address(vault), _debtOutstanding);
                return _debtOutstanding;
            }
        }
        return 0;
    }

    /**
     * 将空置资金进行投资
     **/
    function investInner() internal override {
        uint256 amount = want.balanceOf(address(this));
        if (amount > 0) {
            want.safeApprove(fVault, 0);
            want.safeApprove(fVault, amount);
            HarvestVault(fVault).deposit(amount);

            //stake
            uint256 fTokenAmount = IERC20(fVault).balanceOf(address(this));

            IERC20(fVault).safeApprove(fPool, 0);
            IERC20(fVault).safeApprove(fPool, fTokenAmount);
            HarvestStakePool(fPool).stake(fTokenAmount);

        }
    }

    function migrate(address _newStrategy) external override {}

    function getInvestVaultAssets() external view override returns (uint256) {
        uint256 totalAsset = IERC20(fVault).totalSupply().mul(HarvestVault(fVault).getPricePerFullShare()).div(10 ** HarvestVault(fVault).decimals());

        return totalAsset;
    }
}
