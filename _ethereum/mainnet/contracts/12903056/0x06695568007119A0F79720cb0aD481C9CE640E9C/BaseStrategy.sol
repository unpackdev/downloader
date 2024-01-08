pragma solidity >=0.5.17 <0.8.4;

import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";


import "./IStrategy.sol";
import "./IVault.sol";

abstract contract BaseStrategy {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    string public name;

    uint16 public protocol;

    IVault public vault;

    address[] public tokens;

    uint256 internal constant BASIS_PRECISION = 1e18;
    //基础收益率，初始化时为1000000
    uint256 internal basisProfitRate;
    //有效时长，用于计算apy，若策略没有资金时，不算在有效时长内
    uint256 internal effectiveTime;
    //上次doHardwork的时间
    uint256 public lastDoHardworkTimestamp = 0;

    function getTokens() external view returns (address[] memory) {
        return tokens;
    }

    function setApy(uint256 nextBasisProfitRate, uint256 nextEffectiveTime) external onlyGovernance {

        basisProfitRate = nextBasisProfitRate;
        effectiveTime = nextEffectiveTime;
        vault.strategyUpdate(this.investedUnderlyingBalance(),apy());
    }

    //10000表示100%，当前apy的算法是一直累计过去的变化，有待改进
    function apy() public view returns (uint256) {

        if (basisProfitRate <= BASIS_PRECISION) {
            return 0;
        }
        if (effectiveTime == 0) {
            return 0;
        }
        return (31536000 * (basisProfitRate - BASIS_PRECISION) * 10000) / (BASIS_PRECISION * effectiveTime);
    }


    modifier onlyGovernance() {
        require(msg.sender == vault.governance(), '!only governance');
        _;
    }

    modifier onlyVault() {
        require(msg.sender == address(vault), '!only vault');
        _;
    }

    function initialize(
        string memory _name,
        uint16 _protocol,
        address _vault,
        address[] memory _tokens
    ) internal {
        name = _name;
        protocol = _protocol;
        vault = IVault(_vault);
        tokens = _tokens;
        effectiveTime = 0;
        basisProfitRate = BASIS_PRECISION;
    }



    /**
     * 计算基础币与其它币种的数量关系
     * 如该池是CrvEURS池，underlying是USDT数量，返回的则是 EURS、SEUR的数量
     **/
    function calculate(uint256 amountUnderlying) external view virtual returns (uint256[] memory, uint256[] memory);

    function withdrawAllToVault() external virtual;

    /**
     * amountUnderlying:需要的基础代币数量
     **/
    function withdrawToVault(uint256 amountUnderlying) external virtual;

    /**
     * 第三方池的净值
     **/
    function getPricePerFullShare() external view virtual returns (uint256);

    /**
     * 已经投资的underlying数量，策略实际投入的是不同的稳定币，这里涉及待投稳定币与underlying之间的换算
     **/
    function investedUnderlyingBalance() external view virtual returns (uint256);

    /**
     * 查看策略投资池子的总资产
     **/
    function getInvestVaultAssets() external view virtual returns (uint256);

    /**
     * 针对策略的作业：
     * 1.提矿 & 换币（矿币换成策略所需的稳定币？）
     * 2.计算apy
     * 3.投资
     **/
    function doHardWork() external onlyGovernance{
        doHardWorkInner();
        vault.strategyUpdate(this.investedUnderlyingBalance(),apy());
        lastDoHardworkTimestamp = block.timestamp;
    }

    function doHardWorkInner() internal virtual;

    function calculateProfitRate(uint256 previousInvestedAssets,int assetsDelta) internal {
        if (assetsDelta < 0)return;
        uint256 secondDelta = block.timestamp - lastDoHardworkTimestamp;
        if (secondDelta > 10 && assetsDelta != 0){
            effectiveTime += secondDelta;
            uint256 dailyProfitRate = uint256(assetsDelta>0?assetsDelta:-assetsDelta) * BASIS_PRECISION / previousInvestedAssets;
            if (assetsDelta > 0){
                basisProfitRate = (BASIS_PRECISION + dailyProfitRate) * basisProfitRate / BASIS_PRECISION;
            } else {
                basisProfitRate = (BASIS_PRECISION - dailyProfitRate) * basisProfitRate / BASIS_PRECISION;
            }

        }
    }

    /**
     * 策略迁移
     **/
    function migrate(address _newStrategy) external virtual;
}
