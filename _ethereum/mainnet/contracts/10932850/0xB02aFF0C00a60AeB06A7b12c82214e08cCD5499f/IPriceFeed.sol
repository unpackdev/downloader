pragma solidity ^0.6.2;

interface IPriceFeed {
    function getLatestPriceToken0() external view virtual returns (uint);

    function getLatestPriceToken1() external view virtual returns (uint);
}