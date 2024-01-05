pragma solidity ^0.5.16;

import "./CErc20.sol";

interface SUKUPriceOracleInterface {
    function getUnderlyingPrice(CToken cToken) external view returns (uint);
    function assetPrices(address asset) external view returns (uint);
    /// Admin functions
    function setUnderlyingPrice(CToken cToken, uint underlyingPriceMantissa) external;
    function setDirectPrice(address asset, uint price) external;
}