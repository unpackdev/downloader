// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.18;

import "./OwnableUpgradeable.sol";
import "./EnumerableSetUpgradeable.sol";
import "./IKyokoPoolAddressesProvider.sol";

contract KyokoPoolAddressesProvider is
    OwnableUpgradeable,
    IKyokoPoolAddressesProvider
{
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    string private _marketId;
    mapping(bytes32 => EnumerableSetUpgradeable.AddressSet) private _roleMembers;

    bytes32 private constant LENDING_POOL = "LENDING_POOL";
    bytes32 private constant LENDING_POOL_LIQUIDATOR =
        "LENDING_POOL_LIQUIDATOR";
    bytes32 private constant LENDING_POOL_CONFIGURATOR =
        "LENDING_POOL_CONFIGURATOR";
    bytes32 private constant LENDING_POOL_FACTORY = "LENDING_POOL_FACTORY";
    bytes32 private constant POOL_ADMIN = "POOL_ADMIN";
    bytes32 private constant EMERGENCY_ADMIN = "EMERGENCY_ADMIN";
    bytes32 private constant NFT_PRICE_ORACLE = "NFT_PRICE_ORACLE";
    bytes32 private constant NFT_RATE_STRATEGY = "NFT_RATE_STRATEGY";

    function initialize(string memory marketId) external initializer {
        __Ownable_init();
        _setMarketId(marketId);
    }

    /**
     * @dev Returns the id of the Kyoko market to which this contracts points to
     * @return The market id
     **/
    function getMarketId() external view override returns (string memory) {
        return _marketId;
    }

    /**
     * @dev Allows to set the market which this KyokoPoolAddressesProvider represents
     * @param marketId The market id
     */
    function setMarketId(string memory marketId) external override onlyOwner {
        _setMarketId(marketId);
    }

    /**
     * @dev Sets an address for an id replacing the address saved in the addresses map
     * IMPORTANT Use this function carefully, as it will do a hard replacement
     * @param id The id
     * @param newAddress The address to set
     */
    function setAddress(bytes32 id, address newAddress)
        external
        override
        onlyOwner
    {
        _roleMembers[id].add(newAddress);
        emit AddressSet(id, newAddress);
    }

    function revokeAddress(bytes32 id, address oldAddress) external override onlyOwner {
        _roleMembers[id].remove(oldAddress);
        emit AddressRevoke(id, oldAddress);
    }

    /**
     * @dev Returns an address by id
     * @return The address
     */
    function getAddress(bytes32 id) public view override returns (address[] memory) {
        return _roleMembers[id].values();
    }

    function hasRole(bytes32 id, address account) public view override returns (bool) {
        return _roleMembers[id].contains(account);
    }

    /**
     * @dev Returns the address of the KyokoPool proxy
     * @return The KyokoPool proxy address
     **/
    function getKyokoPool() external view override returns (address[] memory) {
        return getAddress(LENDING_POOL);
    }

    function isKyokoPool(address account) external view override returns (bool) {
        return hasRole(LENDING_POOL, account);
    }

    function setKyokoPool(address pool) external override onlyOwner {
        _roleMembers[LENDING_POOL].add(pool);
        emit KyokoPoolUpdated(pool);
    }

    function getKyokoPoolLiquidator() external view override returns (address[] memory) {
        return getAddress(LENDING_POOL_LIQUIDATOR);
    }

    function isLiquidator(address account) external view override returns (bool) {
        return hasRole(LENDING_POOL_LIQUIDATOR, account);
    }

    function setKyokoPoolLiquidator(address liquidator)
        external
        override
        onlyOwner
    {
        _roleMembers[LENDING_POOL_LIQUIDATOR].add(liquidator);
        emit KyokoPoolLiquidatorUpdated(liquidator);
    }

    function getKyokoPoolConfigurator()
        external
        view
        override
        returns (address[] memory)
    {
        return getAddress(LENDING_POOL_CONFIGURATOR);
    }

    function isConfigurator(address account) external view override returns (bool) {
        return hasRole(LENDING_POOL_CONFIGURATOR, account);
    }

    function setKyokoPoolConfigurator(address configurator)
        external
        override
        onlyOwner
    {
        _roleMembers[LENDING_POOL_CONFIGURATOR].add(configurator);
        emit KyokoPoolConfiguratorUpdated(configurator);
    }

    function getKyokoPoolFactory() external view override returns (address[] memory) {
        return getAddress(LENDING_POOL_FACTORY);
    }

    function isFactory(address account) external view override returns (bool) {
        return hasRole(LENDING_POOL_FACTORY, account);
    }

    function setKyokoPoolFactory(address factory) external override onlyOwner {
        _roleMembers[LENDING_POOL_FACTORY].add(factory);
        emit KyokoPoolFactoryUpdated(factory);
    }

    /**
     * @dev The functions below are getters/setters of addresses that are outside the context
     * of the protocol hence the upgradable proxy pattern is not used
     **/

    function getPoolAdmin() external view override returns (address[] memory) {
        return getAddress(POOL_ADMIN);
    }

    function isAdmin(address account) external view override returns (bool) {
        return hasRole(POOL_ADMIN, account);
    }

    function setPoolAdmin(address admin) external override onlyOwner {
        _roleMembers[POOL_ADMIN].add(admin);
        emit ConfigurationAdminUpdated(admin);
    }

    function getEmergencyAdmin() external view override returns (address[] memory) {
        return getAddress(EMERGENCY_ADMIN);
    }

    function isEmergencyAdmin(address account) external view override returns (bool) {
        return hasRole(EMERGENCY_ADMIN, account);
    }

    function setEmergencyAdmin(address emergencyAdmin)
        external
        override
        onlyOwner
    {
        _roleMembers[EMERGENCY_ADMIN].add(emergencyAdmin);
        emit EmergencyAdminUpdated(emergencyAdmin);
    }

    function getPriceOracle() external view override returns (address[] memory) {
        return getAddress(NFT_PRICE_ORACLE);
    }

    function isOracle(address account) external view override returns (bool) {
        return hasRole(NFT_PRICE_ORACLE, account);
    }

    function setPriceOracle(address priceOracle) external override onlyOwner {
        _roleMembers[NFT_PRICE_ORACLE].add(priceOracle);
        emit PriceOracleUpdated(priceOracle);
    }

    function getRateStrategy() external view override returns (address[] memory) {
        return getAddress(NFT_RATE_STRATEGY);
    }

    function isStrategy(address account) external view override returns (bool) {
        return hasRole(NFT_RATE_STRATEGY, account);
    }

    function setRateStrategy(address rateStrategy) external override onlyOwner {
        _roleMembers[NFT_RATE_STRATEGY].add(rateStrategy);
        emit RateStrategyUpdated(rateStrategy);
    }

    function _setMarketId(string memory marketId) internal {
        _marketId = marketId;
        emit MarketIdSet(marketId);
    }
}
