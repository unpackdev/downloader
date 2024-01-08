pragma solidity >=0.5.17 <0.8.4;

interface IStrategy {

    //该策略属于的协议类型
    function protocol() external view returns (uint256);

    //该策略需要的token地址
    function want() external view returns (address);

    function name() external view returns (string memory);
    // 获取该策略对应池的apy
    function apy() external view returns (uint256);
    // 更新该策略对应池apy，留给keeper调用
    function updateApy(uint256 _apy) external;
    //该策略的vault地址
    function vault() external view returns (address);

    //    function deposit(uint256 mount) external;

    //需要提取指定数量的token,返回提取导致的loss数量token
    function withdraw(uint256 _amount) external returns (uint256);

    //计算策略的APY
    function calAPY() external returns (uint256);

    //该策略所有的资产（priced in want）
    function estimatedTotalAssets() external view returns (uint256);

    //策略迁移
    function migrate(address _newStrategy) external;

    //查看策略投资池子的总数量（priced in want）
    function getInvestVaultAssets() external view returns (uint256);

    /**
    * correspondingShares：待提取xToken数
    * totalShares：总xToken数
    **/
    function withdrawToVault(uint256 correspondingShares, uint256 totalShares) external returns  (uint256 value, uint256 partialClaimValue, uint256 claimValue) ;

    /**
    * 无人提取时，通过调用该方法计算策略净值
    **/
    function withdrawOneToken() external returns  (uint256 value, uint256 partialClaimValue, uint256 claimValue);



    /**
    * 退回超出部分金额
    **/
    function cutOffPosition(uint256 _debtOutstanding) external returns (uint256);

    /**
    * 将空置资金进行投资
    **/
    function invest() external;
}