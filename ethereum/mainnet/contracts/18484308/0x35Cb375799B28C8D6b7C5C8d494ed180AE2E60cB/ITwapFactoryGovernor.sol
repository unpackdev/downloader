pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9



interface ITwapFactoryGovernor {
    event FactorySet(address factory);
    event DelaySet(address delay);
    event ProtocolFeeRatioSet(uint256 protocolFeeRatio);
    event EthTransferCostSet(uint256 ethTransferCost);
    event FeeDistributed(address indexed token, address indexed pair, uint256 lpAmount, uint256 protocolAmount);
    event OwnerSet(address owner);
    event WithdrawToken(address token, address to, uint256 amount);

    function owner() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function factory() external view returns (address);

    function delay() external view returns (address);

    function protocolFeeRatio() external view returns (uint256);

    function ethTransferCost() external view returns (uint256);

    function setFactoryOwner(address) external;

    function setFactory(address) external;

    function setOwner(address) external;

    function setMintFee(
        address tokenA,
        address tokenB,
        uint256 fee
    ) external;

    function setBurnFee(
        address tokenA,
        address tokenB,
        uint256 fee
    ) external;

    function setSwapFee(
        address tokenA,
        address tokenB,
        uint256 fee
    ) external;

    function setOracle(
        address tokenA,
        address tokenB,
        address oracle
    ) external;

    function setTrader(
        address tokenA,
        address tokenB,
        address trader
    ) external;

    function setDelay(address) external;

    function setProtocolFeeRatio(uint256 _protocolFeeRatio) external;

    function setEthTransferCost(uint256 _ethTransferCost) external;

    function createPair(
        address tokenA,
        address tokenB,
        address oracle,
        address trader
    ) external returns (address pair);

    function collectFees(
        address tokenA,
        address tokenB,
        address to
    ) external;

    function withdrawLiquidity(
        address tokenA,
        address tokenB,
        uint256 amount,
        address to
    ) external;

    function withdrawToken(
        address token,
        uint256 amount,
        address to
    ) external;

    function distributeFees(address tokenA, address tokenB) external;

    function distributeFees(
        address tokenA,
        address tokenB,
        address pairAddress
    ) external;

    function feesToDistribute(address tokenA, address tokenB)
        external
        view
        returns (uint256 fee0ToDistribute, uint256 fee1ToDistribute);
}
