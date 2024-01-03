pragma solidity ^0.6.0;

/************
@title IPriceOracleGetter interface
@notice Interface for the Aave price oracle.*/
interface IPriceOracleGetter {
    function getAssetPrice(address _asset) external view returns (uint256);
}