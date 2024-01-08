pragma solidity 0.6.6;

/**
@title ILendingPoolAddressesProvider interface
@notice provides the interface to fetch the LendingPoolCore address
 */

interface ILendingPoolAddressesProvider {

    function getLendingPool() external view returns (address);

    function getLendingPoolCore() external view returns (address payable);

    function getLendingPoolConfigurator() external view returns (address);

    function getLendingPoolDataProvider() external view returns (address);

    function getLendingPoolParametersProvider() external view returns (address);


    function getLendingPoolLiquidationManager() external view returns (address);

    function getLendingPoolManager() external view returns (address);

    function getPriceOracle() external view returns (address);

    function getLendingRateOracle() external view returns (address);

}
