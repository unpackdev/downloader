pragma solidity >=0.5.17 <0.8.4;

interface IVault {
    function name() external view returns (string calldata);

    function symbol() external view returns (string calldata);

    function decimals() external view returns (uint256);

    function governance() external view returns (address);

    /**
     * USDT地址
     **/
    function underlying() external view returns (address);

    /**
     * Vault净值
     **/
    function getPricePerFullShare() external view returns (uint256);

    /**
     * 总锁仓量
     **/
    function tlv() external view returns (uint256);

    function deposit(uint256 amountWei) external;

    function withdraw(uint256 numberOfShares) external;

    function addStrategy(address _strategy) external;

    function removeStrategy(address _strategy) external;

    function strategyUpdate(uint256 newTotalAssets, uint256 apy) external;

    /**
     * 策略列表
     **/
    function strategies() external view returns (address[] memory);

    /**
     * 分两种情况：
     * 不足一周时，维持Vault中USDT数量占总资金的5%，多余的投入到apy高的策略中，不足时从低apy策略中赎回份额来补够
     * 到达一周时，统计各策略apy，按照资金配比规则进行调仓（统计各策略需要的稳定币数量，在Vault中汇总后再分配）
     **/
    function doHardWork() external;

    struct StrategyState {
        uint256 totalAssets; //当前总资产
        uint256 totalDebt; //投入未返还成本
    }

    function strategyState(address strategyAddress) external view returns (StrategyState memory);

    /**
     * 获取总成本
     */
    function totalCapital() external view returns (uint256);

    /**
     * 获取总估值
     */
    function totalAssets() external view returns (uint256);

    /**
     * 获取策略投资总额
     */
    function strategyTotalAssetsValue() external view returns (uint256);

}
