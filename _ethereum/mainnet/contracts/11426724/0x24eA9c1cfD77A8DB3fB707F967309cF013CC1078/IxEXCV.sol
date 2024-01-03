pragma solidity >=0.6.6;

interface IxEXCV {
    function liquidityPairs() external view returns (address[] memory);
    function factory() external view returns (address);
    function excvEthPair() external view returns (address);
    function getEXCV() external view returns (address);

    function initialize(address _factory) external;
    function redeem(address recipient) external;
    function redeemPair(address recipient, address pair, uint claimedLiquidityAmount) external;
    function addPair(address tokenA, address tokenB) external;
    function pairBalanceOf(address owner, address pair) external view returns (uint);
}