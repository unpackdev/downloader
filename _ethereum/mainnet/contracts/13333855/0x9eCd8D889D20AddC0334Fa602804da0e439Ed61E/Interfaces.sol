// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface RegistryInterface {
    function pETH() external view returns (address);
}

interface FactoryInterface {
    function registry() external view returns (address);
}

interface PTokenInterface {
    function exchangeRateStored() external view returns (uint);
    function borrowBalanceStored(address account) external view returns (uint);
    function underlying() external view returns (address);
}

interface CalcPoolPrice {
    function getPoolPriceInUSD(address asset) external view returns (uint);
}

interface PriceOracle {
    function getUnderlyingPrice(address pToken) external view returns (uint);
    function getPriceInUSD(address underlying) external view returns (uint);
}

interface ControllerInterface {
    function getOracle() external view returns (PriceOracle);
    function getAssetsIn(address account) external view returns (address[] memory);
    function factory() external view returns (address);
}

interface AggregatorInterface {
    function latestAnswer() external view returns (int256);
}

interface ConvertInterface {
    function getPTokenInAmount(address user) external view returns (uint);
    function pTokenFrom() external view returns (address);
}
