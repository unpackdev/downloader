pragma solidity =0.6.2;

interface IUniswapV1Factory {
    function getExchange(address) external view returns (address);
}
