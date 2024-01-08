pragma solidity >=0.5.17 <0.8.4;

interface IStrategy {

//    function underlying() external view returns (address);
    function vault() external view returns (address);

    function name() external pure returns (string calldata);

    /**
    * 第三方池需要的代币地址列表
    **/
    function getTokens() external view returns (address[] memory);

    function apy() external view returns (uint256);

    /**
    * 计算基础币与其它币种的数量关系
    * 如该池是CrvEURS池，underlying是USDT数量，返回的则是 EURS、SEUR的数量
    **/
    function calculate(uint256 amountUnderlying) external view returns (uint256[] memory);

    function withdrawAllToVault() external;

    /**
    * amountUnderlying:需要的基础代币数量
    **/
    function withdrawToVault(uint256 amountUnderlying) external;


    /**
    * 第三方池的净值
    **/
    function getPricePerFullShare() external view returns (uint256);

    /**
    * 已经投资的underlying数量，策略实际投入的是不同的稳定币，这里涉及待投稳定币与underlying之间的换算
    **/
    function investedUnderlyingBalance() external view returns (uint256);

    /**
    * 查看策略投资池子的总数量（priced in want）
    **/
    function getInvestVaultAssets() external view returns (uint256);


    /**
    * 针对策略的作业：
    * 1.提矿 & 换币（矿币换成策略所需的稳定币？）
    * 2.计算apy
    * 3.投资
    **/
    function doHardWork() external;

    /**
    * 策略迁移
    **/
    function migrate(address _newStrategy) external virtual;
}
