// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

// dependencies
import "./Multicall.sol";
// interfaces
import "./IBeaconProxyController.sol";
import "./IProxyController.sol";
// libraries
import "./AddressResolverLib.sol";
import "./Contracts.sol";
// mixins
import "./MixinAddressResolver.sol";
// utils
import "./UpgradeableBeacon.sol";
import "./Ownable.sol";
import "./Proxyable.sol";
import "./UpgradeabilityBeaconProxy.sol";
// storages
import "./BeaconProxyControllerStorage.sol";

/**
 * @notice Implements the management of beacon proxy contracts.
 *
 * All beacon proxy contracts are deployed from this contract.
 * This contract is also used to update the beacon proxy implementation.
 */
contract BeaconProxyController is
    IBeaconProxyController,
    MixinAddressResolver,
    Ownable,
    Proxyable,
    Multicall
{
    /**
     * @notice Initializes the contract.
     * @dev Function is invoked by the proxy contract when the contract is added to the ProxyController.
     * @param _owner The address of the contract owner
     * @param _resolver The address of the Address Resolver contract
     */
    function initialize(address _owner, address _resolver) public initializer onlyProxy {
        _transferOwnership(_owner);
        registerAddressResolver(_resolver);
    }

    // @inheritdoc MixinAddressResolver
    function requiredContracts() public pure override returns (bytes32[] memory contracts) {
        contracts = new bytes32[](1);
        contracts[0] = Contracts.LENDING_MARKET_CONTROLLER;
    }

    /**
     * @notice Gets the beacon proxy address to the selected name.
     * @param beaconName The cache name of the beacon proxy
     * @return beaconProxyAddress The beacon proxy address
     */
    function getBeaconProxyAddress(
        bytes32 beaconName
    ) external view override returns (address beaconProxyAddress) {
        beaconProxyAddress = Storage.slot().registeredBeaconProxies[beaconName];
        if (beaconProxyAddress == address(0)) revert NoBeaconProxyContract();

        UpgradeabilityBeaconProxy beaconProxy = UpgradeabilityBeaconProxy(
            payable(beaconProxyAddress)
        );

        if (beaconProxy.implementation() == address(0)) revert InvalidProxyContract();
    }

    /**
     * @notice Sets the implementation contract of FutureValueVault
     * @param newImpl The address of implementation contract
     */
    function setFutureValueVaultImpl(address newImpl) external override onlyOwner {
        _updateBeaconImpl(BeaconContracts.FUTURE_VALUE_VAULT, newImpl);
    }

    /**
     * @notice Sets the implementation contract of LendingMarket
     * @param newImpl The address of implementation contract
     */
    function setLendingMarketImpl(address newImpl) external override onlyOwner {
        _updateBeaconImpl(BeaconContracts.LENDING_MARKET, newImpl);
    }

    /**
     * @notice Deploys new FutureValueVault
     * @notice Reverts on deployment market with existing currency and term
     */
    function deployFutureValueVault()
        external
        override
        onlyLendingMarketController
        returns (address futureValue)
    {
        bytes memory data = abi.encodeWithSignature("initialize(address)", address(resolver()));
        futureValue = _createProxy(BeaconContracts.FUTURE_VALUE_VAULT, data);
    }

    /**
     * @notice Deploys new LendingMarket
     * @param _ccy Main currency for new lending market
     * @param _orderFeeRate The order fee rate received by protocol
     * @param _cbLimitRange The circuit breaker limit range
     * @return market The proxy contract address of created lending market
     */
    function deployLendingMarket(
        bytes32 _ccy,
        uint256 _orderFeeRate,
        uint256 _cbLimitRange
    ) external override onlyLendingMarketController returns (address market) {
        bytes memory data = abi.encodeWithSignature(
            "initialize(address,bytes32,uint256,uint256)",
            address(resolver()),
            _ccy,
            _orderFeeRate,
            _cbLimitRange
        );
        market = _createProxy(BeaconContracts.LENDING_MARKET, data);
    }

    /**
     * @notice Updates admin addresses of beacon proxy contract
     * @param newAdmin The address of new admin
     * @param destinations The destination contract addresses
     */
    function changeBeaconProxyAdmins(
        address newAdmin,
        address[] calldata destinations
    ) external onlyOwner {
        for (uint256 i; i < destinations.length; i++) {
            UpgradeabilityBeaconProxy proxy = UpgradeabilityBeaconProxy(payable(destinations[i]));
            proxy.changeAdmin(newAdmin);
        }
    }

    function _createProxy(bytes32 beaconName, bytes memory data) internal returns (address) {
        address beaconProxyAddress = Storage.slot().registeredBeaconProxies[beaconName];
        if (beaconProxyAddress == address(0)) revert NoBeaconProxyContract();

        return address(new UpgradeabilityBeaconProxy(beaconProxyAddress, data));
    }

    function _updateBeaconImpl(
        bytes32 name,
        address newAddress
    ) internal returns (address beaconProxyAddress) {
        beaconProxyAddress = Storage.slot().registeredBeaconProxies[name];
        UpgradeableBeacon beacon;

        if (beaconProxyAddress == address(0)) {
            beacon = new UpgradeableBeacon(newAddress);

            Storage.slot().registeredBeaconProxies[name] = beaconProxyAddress = address(beacon);

            emit BeaconProxyUpdated(name, beaconProxyAddress, newAddress, address(0));
        } else {
            beacon = UpgradeableBeacon(beaconProxyAddress);
            address oldAddress = beacon.implementation();
            beacon.upgradeTo(newAddress);
            emit BeaconProxyUpdated(name, beaconProxyAddress, newAddress, oldAddress);
        }
    }
}
