pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "./Initializable.sol";
import "./AccessControlUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./EnumerableSetUpgradeable.sol";
import "./EnumerableMapUpgradeable.sol";

import "./IAPWToken.sol";

/**
 * @title Registry Contract
 * @notice Keeps a record of all valid contract addresses currently used in the protocol
 */
contract Registry is Initializable, AccessControlUpgradeable {
    using SafeMathUpgradeable for uint256;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using EnumerableMapUpgradeable for EnumerableMapUpgradeable.UintToAddressMap;

    /* ACR ROLE */
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant CONTROLLER_ROLE = keccak256("CONTROLLER_ROLE");

    /* Addresses */
    address private apw;
    address private vesting;
    address private controller;
    address private treasury;
    address private gaugeController;
    EnumerableSetUpgradeable.AddressSet private futures;

    /* Futures Contracts */
    EnumerableSetUpgradeable.AddressSet private futureVaultsLogic;
    EnumerableSetUpgradeable.AddressSet private futureWalletsLogic;
    EnumerableSetUpgradeable.AddressSet private futuresLogic;

    /* Futures Platforms Contracts */
    EnumerableSetUpgradeable.AddressSet private futureFactories;
    mapping(address => string) private futureFactoriesNames;

    string[] private futurePlatformsNames;
    mapping(string => address) private futurePlatformToDeployer;
    mapping(string => futurePlatform) private futurePlatformsName;

    /* Struct */
    struct futurePlatform {
        address future;
        address futureVault;
        address futureWallet;
    }

    /* Utils */
    address private mathsUtils;
    address private namingUtils;

    /* Proxy */
    address private proxyFactory;
    address private liquidityGaugeLogic;
    address private APWineIBTLogic;
    address private FYTLogic;

    event RegistryUpdate(string _contractName, address _old, address _new);
    event FuturePlatformAdded(
        address _futureFactory,
        string _futurePlatformName,
        address _future,
        address _futureWallet,
        address _futureVault
    );

    /**
     * @notice Initializer of the contract
     * @param _admin the address of the admin of the contract
     */
    function initialize(address _admin) public initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        _setupRole(ADMIN_ROLE, _admin);
    }

    /* Setters */

    /**
     * @notice Setter for the treasury address
     * @param _newTreasury the address of the new treasury
     */
    function setTreasury(address _newTreasury) public {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        emit RegistryUpdate("Treasury", treasury, _newTreasury);
        treasury = _newTreasury;
    }

    /**
     * @notice Setter for the gauge controller address
     * @param _newGaugeController the address of the new gauge controller
     */
    function setGaugeController(address _newGaugeController) public {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        emit RegistryUpdate("GaugeController", gaugeController, _newGaugeController);
        gaugeController = _newGaugeController;
    }

    /**
     * @notice Setter for the controller address
     * @param _newController the address of the new controller
     */
    function setController(address _newController) public {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        emit RegistryUpdate("Controller", controller, _newController);
        _setupRole(CONTROLLER_ROLE, _newController);
        revokeRole(CONTROLLER_ROLE, controller);
        controller = _newController;
    }

    /**
     * @notice Setter for the APW token address
     * @param _newAPW the address of the APW token
     */
    function setAPW(address _newAPW) public {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        emit RegistryUpdate("APW", apw, _newAPW);
        apw = _newAPW;
    }

    /* Getters */
    /**
     * @notice Getter for the DAO address
     * @return the address of the DAO that has admin rights on the APW token
     */
    function getDAOAddress() public view returns (address) {
        return IAPWToken(apw).getDAO();
    }

    /**
     * @notice Getter for the APW token address
     * @return the address the APW token
     */
    function getAPWAddress() public view returns (address) {
        return apw;
    }

    /**
     * @notice Getter for the vesting contract address
     * @return the vesting contract address
     */
    function getVestingAddress() public view returns (address) {
        return IAPWToken(apw).getVestingContract();
    }

    /**
     * @notice Getter for the controller address
     * @return the address of the controller
     */
    function getControllerAddress() public view returns (address) {
        return controller;
    }

    /**
     * @notice Getter for the treasury address
     * @return the address of the treasury
     */
    function getTreasuryAddress() public view returns (address) {
        return treasury;
    }

    /**
     * @notice Getter for the gauge controller address
     * @return the address of the gauge controller
     */
    function getGaugeControllerAddress() public view returns (address) {
        return gaugeController;
    }

    /* Logic setters */

    /**
     * @notice Setter for the proxy factory address
     * @param _proxyFactory the address of the new proxy factory
     */
    function setProxyFactory(address _proxyFactory) public {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        emit RegistryUpdate("Proxy Factory", proxyFactory, _proxyFactory);
        proxyFactory = _proxyFactory;
    }

    /**
     * @notice Setter for the liquidity gauge address
     * @param _liquidityGaugeLogic the address of the new liquidity gauge logic
     */
    function setLiquidityGaugeLogic(address _liquidityGaugeLogic) public {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        emit RegistryUpdate("LiquidityGauge logic", liquidityGaugeLogic, _liquidityGaugeLogic);
        liquidityGaugeLogic = _liquidityGaugeLogic;
    }

    /**
     * @notice Setter for the APWine IBTlogic address
     * @param _APWineIBTLogic the address of the new APWine IBTlogic
     */
    function setAPWineIBTLogic(address _APWineIBTLogic) public {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        emit RegistryUpdate("APWineIBT logic", APWineIBTLogic, _APWineIBTLogic);
        APWineIBTLogic = _APWineIBTLogic;
    }

    /**
     * @notice Setter for the APWine FYTlogic address
     * @param _FYTLogic the address of the new APWine IBT logic
     */
    function setFYTLogic(address _FYTLogic) public {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        emit RegistryUpdate("FYT logic", _FYTLogic, _FYTLogic);
        FYTLogic = _FYTLogic;
    }

    /**
     * @notice Setter for the math utils address
     * @param _mathsUtils the address of the new math utils
     */
    function setMathsUtils(address _mathsUtils) public {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        emit RegistryUpdate("Maths utils", mathsUtils, _mathsUtils);
        mathsUtils = _mathsUtils;
    }

    /**
     * @notice Setter for the naming utils address
     * @param _namingUtils the address of the new naming utils
     */
    function setNamingUtils(address _namingUtils) public {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        emit RegistryUpdate("Naming utils", namingUtils, _namingUtils);
        namingUtils = _namingUtils;
    }

    /* Logic getters */

    /**
     * @notice Getter for the proxy factory address
     * @return the proxy factory address
     */
    function getProxyFactoryAddress() public view returns (address) {
        return proxyFactory;
    }

    /**
     * @notice Getter for liquidity gauge logic address
     * @return the liquidity gauge logic address
     */
    function getLiquidityGaugeLogicAddress() public view returns (address) {
        return liquidityGaugeLogic;
    }

    /**
     * @notice Getter for APWine IBT logic address
     * @return the APWine IBT logic address
     */
    function getAPWineIBTLogicAddress() public view returns (address) {
        return APWineIBTLogic;
    }

    /**
     * @notice Getter for APWine FYT logic address
     * @return the APWine FYT logic address
     */
    function getFYTLogicAddress() public view returns (address) {
        return FYTLogic;
    }

    /* Utils getters */

    /**
     * @notice Getter for math utils address
     * @return the math utils address
     */
    function getMathsUtils() public view returns (address) {
        return mathsUtils;
    }

    /**
     * @notice Getter for naming utils address
     * @return the naming utils address
     */
    function getNamingUtils() public view returns (address) {
        return namingUtils;
    }

    /* Futures Deployer */

    /**
     * @notice Register a new future factory in the registry
     * @param _futureFactory the address of the future factory contract
     * @param _futureFactoryName the name of the future factory
     */
    function addFutureFactory(address _futureFactory, string memory _futureFactoryName) public {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        futureFactories.add(_futureFactory);
        futureFactoriesNames[_futureFactory] = _futureFactoryName;
    }

    /**
     * @notice Getter to check if a future factory is registered
     * @param _futureFactory the address of the future factory contract to check the registration of
     * @return true if it is, false otherwise
     */
    function isRegisteredFutureFactory(address _futureFactory) public view returns (bool) {
        return futureFactories.contains(_futureFactory);
    }

    /**
     * @notice Getter for the future factory registered at an index
     * @param _index the index of the future factory to return
     * @return the address of the corresponding future factory
     */
    function getFutureFactoryAt(uint256 _index) external view returns (address) {
        return futureFactories.at(_index);
    }

    /**
     * @notice Getter for number of future factories registered
     * @return the number of future factories registered
     */
    function futureFactoryCount() external view returns (uint256) {
        return futureFactories.length();
    }

    /**
     * @notice Getter for the name of a future factory contract
     * @param _futureFactory the address of a future factory
     * @return the name of the corresponding future factory contract
     */
    function getFutureFactoryName(address _futureFactory) external view returns (string memory) {
        require(futureFactories.contains(_futureFactory), "invalid future platform deployer");
        return futureFactoriesNames[_futureFactory];
    }

    /* Future Platform */

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
    ) public {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        require(futureFactories.contains(_futureFactory), "invalid future platform deployer address");

        futurePlatform memory newFuturePlaform =
            futurePlatform({futureVault: _futureVault, futureWallet: _futureWallet, future: _future});

        if (!isRegisteredFuturePlatform(_futurePlatformName)) futurePlatformsNames.push(_futurePlatformName);

        futurePlatformsName[_futurePlatformName] = newFuturePlaform;
        futurePlatformToDeployer[_futurePlatformName] = _futureFactory;
        emit FuturePlatformAdded(_futureFactory, _futurePlatformName, _future, _futureWallet, _futureVault);
    }

    /**
     * @notice Remove a future platform from the registry
     * @param _futurePlatformName the name of the future platform to remove from the registry
     */
    function removeFuturePlatform(string memory _futurePlatformName) public {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        require(isRegisteredFuturePlatform(_futurePlatformName), "invalid future platform name");

        for (uint256 i = 0; i < futurePlatformsNames.length; i++) {
            // can be optimized
            if (keccak256(bytes(futurePlatformsNames[i])) == keccak256(bytes(_futurePlatformName))) {
                delete futurePlatformsNames[i];
                break;
            }
        }

        delete futurePlatformToDeployer[_futurePlatformName];
        delete futurePlatformsName[_futurePlatformName];
    }

    /**
     * @notice Getter to check if a future platform is registered
     * @param _futurePlatformName the name of the future platform to check the registration of
     * @return true if it is, false otherwise
     */
    function isRegisteredFuturePlatform(string memory _futurePlatformName) public view returns (bool) {
        for (uint256 i = 0; i < futurePlatformsNames.length; i++) {
            if (keccak256(bytes(futurePlatformsNames[i])) == keccak256(bytes(_futurePlatformName))) return true;
        }
        return false;
    }

    /**
     * @notice Getter for the future platform contracts
     * @param _futurePlatformName the name of the future platform
     * @return the addresses of 0) the future logic 1) the future wallet logic 2) the future vault logic
     */
    function getFuturePlatform(string memory _futurePlatformName) public view returns (address[3] memory) {
        futurePlatform memory futurePlatformContracts = futurePlatformsName[_futurePlatformName];
        address[3] memory addressesArrays =
            [futurePlatformContracts.future, futurePlatformContracts.futureWallet, futurePlatformContracts.futureVault];
        return addressesArrays;
    }

    /**
     * @notice Getter the total count of future platforms registered
     * @return the number of future platforms registered
     */
    function futurePlatformsCount() external view returns (uint256) {
        return futurePlatformsNames.length;
    }

    /**
     * @notice Getter the list of platform names registered
     * @return the list of platform names registered
     */
    function getFuturePlatformNames() external view returns (string[] memory) {
        return futurePlatformsNames;
    }

    /* Futures */

    /**
     * @notice Add a future to the registry
     * @param _future the address of the future to add to the registry
     */
    function addFuture(address _future) public {
        require(hasRole(CONTROLLER_ROLE, msg.sender), "Caller is not an admin");
        require(futures.add(_future), "future not added");
    }

    /**
     * @notice Remove a future from the registry
     * @param _future the address of the future to remove from the registry
     */
    function removeFuture(address _future) public {
        require(hasRole(CONTROLLER_ROLE, msg.sender), "Caller is not an admin");
        require(futures.remove(_future), "future not removed");
    }

    /**
     * @notice Getter to check if a future is registered
     * @param _future the address of the future to check the registration of
     * @return true if it is, false otherwise
     */
    function isRegisteredFuture(address _future) external view returns (bool) {
        return futures.contains(_future);
    }

    /**
     * @notice Getter for the future registered at an index
     * @param _index the index of the future to return
     * @return the address of the corresponding future
     */
    function getFutureAt(uint256 _index) external view returns (address) {
        return futures.at(_index);
    }

    /**
     * @notice Getter for number of futures registered
     * @return the number of futures registered
     */
    function futureCount() external view returns (uint256) {
        return futures.length();
    }
}
