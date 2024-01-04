pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

interface IRegistry {
    /**
     * @notice Initializer of the contract
     * @param _admin the address of the admin of the contract
     */
    function initialize(address _admin) external;

    /* Setters */

    /**
     * @notice Setter for the treasury address
     * @param _newTreasury the address of the new treasury
     */
    function setTreasury(address _newTreasury) external;

    /**
     * @notice Setter for the gauge controller address
     * @param _newGaugeController the address of the new gauge controller
     */
    function setGaugeController(address _newGaugeController) external;

    /**
     * @notice Setter for the controller address
     * @param _newController the address of the new controller
     */
    function setController(address _newController) external;

    /**
     * @notice Setter for the APW token address
     * @param _newAPW the address of the APW token
     */
    function setAPW(address _newAPW) external;

    /**
     * @notice Setter for the proxy factory address
     * @param _proxyFactory the address of the new proxy factory
     */
    function setProxyFactory(address _proxyFactory) external;

    /**
     * @notice Setter for the liquidity gauge address
     * @param _liquidityGaugeLogic the address of the new liquidity gauge logic
     */
    function setLiquidityGaugeLogic(address _liquidityGaugeLogic) external;

    /**
     * @notice Setter for the APWine IBT logic address
     * @param _APWineIBTLogic the address of the new APWine IBT logic
     */
    function setAPWineIBTLogic(address _APWineIBTLogic) external;

    /**
     * @notice Setter for the APWine FYT logic address
     * @param _FYTLogic the address of the new APWine FYT logic
     */
    function setFYTLogic(address _FYTLogic) external;

    /**
     * @notice Setter for the maths utils address
     * @param _mathsUtils the address of the new math utils
     */
    function setMathsUtils(address _mathsUtils) external;

    /**
     * @notice Setter for the naming utils address
     * @param _namingUtils the address of the new naming utils
     */
    function setNamingUtils(address _namingUtils) external;

    /**
     * @notice Getter for the controller address
     * @return the address of the controller
     */
    function getControllerAddress() external view returns (address);

    /**
     * @notice Getter for the treasury address
     * @return the address of the treasury
     */
    function getTreasuryAddress() external view returns (address);

    /**
     * @notice Getter for the gauge controller address
     * @return the address of the gauge controller
     */
    function getGaugeControllerAddress() external view returns (address);

    /**
     * @notice Getter for the DAO address
     * @return the address of the DAO that has admin rights on the APW token
     */
    function getDAOAddress() external returns (address);

    /**
     * @notice Getter for the APW token address
     * @return the address the APW token
     */
    function getAPWAddress() external view returns (address);

    /**
     * @notice Getter for the vesting contract address
     * @return the vesting contract address
     */
    function getVestingAddress() external view returns (address);

    /**
     * @notice Getter for the proxy factory address
     * @return the proxy factory address
     */
    function getProxyFactoryAddress() external view returns (address);

    /**
     * @notice Getter for liquidity gauge logic address
     * @return the liquidity gauge logic address
     */
    function getLiquidityGaugeLogicAddress() external view returns (address);

    /**
     * @notice Getter for APWine IBT logic address
     * @return the APWine IBT logic address
     */
    function getAPWineIBTLogicAddress() external view returns (address);

    /**
     * @notice Getter for APWine FYT logic address
     * @return the APWine FYT logic address
     */
    function getFYTLogicAddress() external view returns (address);

    /**
     * @notice Getter for math utils address
     * @return the math utils address
     */
    function getMathsUtils() external view returns (address);

    /**
     * @notice Getter for naming utils address
     * @return the naming utils address
     */
    function getNamingUtils() external view returns (address);

    /* Future factory */

    /**
     * @notice Register a new future factory in the registry
     * @param _futureFactory the address of the future factory contract
     * @param _futureFactoryName the name of the future factory
     */
    function addFutureFactory(address _futureFactory, string memory _futureFactoryName) external;

    /**
     * @notice Getter to check if a future factory is registered
     * @param _futureFactory the address of the future factory contract to check the registration of
     * @return true if it is, false otherwise
     */
    function isRegisteredFutureFactory(address _futureFactory) external view returns (bool);

    /**
     * @notice Getter for the future factory registered at an index
     * @param _index the index of the future factory to return
     * @return the address of the corresponding future factory
     */
    function getFutureFactoryAt(uint256 _index) external view returns (address);

    /**
     * @notice Getter for number of future factories registered
     * @return the number of future factory registered
     */
    function futureFactoryCount() external view returns (uint256);

    /**
     * @notice Getter for name of a future factory contract
     * @param _futureFactory the address of a future factory
     * @return the name of the corresponding future factory contract
     */
    function getFutureFactoryName(address _futureFactory) external view returns (string memory);

    /* Future platform */
    /**
     * @notice Register a new future platform in the registry
     * @param _futureFactory the address of the future factory
     * @param _futurePlatformName the name of the future platform
     * @param _future the address of the future contract logic
     * @param _futureWallet the address of the future wallet contract logic
     * @param _futureVault the name of the future vault contract logic
     */
    function addFuturePlatform(
        address _futureFactory,
        string memory _futurePlatformName,
        address _future,
        address _futureWallet,
        address _futureVault
    ) external;

    /**
     * @notice Getter to check if a future platform is registered
     * @param _futurePlatformName the name of the future platform to check the registration of
     * @return true if it is, false otherwise
     */
    function isRegisteredFuturePlatform(string memory _futurePlatformName) external view returns (bool);

    /**
     * @notice Getter for the future platform contracts
     * @param _futurePlatformName the name of the future platform
     * @return the addresses of 0) the future logic 1) the future wallet logic 2) the future vault logic
     */
    function getFuturePlatform(string memory _futurePlatformName) external view returns (address[3] memory);

    /**
     * @notice Getter the total count of future platftroms registered
     * @return the number of future platforms registered
     */
    function futurePlatformsCount() external view returns (uint256);

    /**
     * @notice Getter the list of platforms names registered
     * @return the list of platform names registered
     */
    function getFuturePlatformNames() external view returns (string[] memory);

    /**
     * @notice Remove a future platform from the registry
     * @param _futurePlatformName the name of the future platform to remove from the registry
     */
    function removeFuturePlatform(string memory _futurePlatformName) external;

    /* Futures */
    /**
     * @notice Add a future to the registry
     * @param _future the address of the future to add to the registry
     */
    function addFuture(address _future) external;

    /**
     * @notice Remove a future from the registry
     * @param _future the address of the future to remove from the registry
     */
    function removeFuture(address _future) external;

    /**
     * @notice Getter to check if a future is registered
     * @param _future the address of the future to check the registration of
     * @return true if it is, false otherwise
     */
    function isRegisteredFuture(address _future) external view returns (bool);

    /**
     * @notice Getter for the future registered at an index
     * @param _index the index of the future to return
     * @return the address of the corresponding future
     */
    function getFutureAt(uint256 _index) external view returns (address);

    /**
     * @notice Getter for number of future registered
     * @return the number of future registered
     */
    function futureCount() external view returns (uint256);
}
