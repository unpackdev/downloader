// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import "./IPoolConfigurator.sol";
import "./IPool.sol";
import "./IInitializableYToken.sol";
import "./INToken.sol";
import "./IInitializableDebtToken.sol";
import "./TransparentAdminUpgradeableProxy.sol";
import "./ReserveConfiguration.sol";
import "./DataTypes.sol";
import "./ConfiguratorInputTypes.sol";

/**
 * @title ConfiguratorLogic library
 *
 * @notice Implements the functions to initialize reserves and update yTokens and debtTokens
 */
library ConfiguratorLogic {
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

    /**
     * @notice Initialize a reserve by creating and initializing yToken and variable debt token
     * @dev Emits the `ReserveInitialized` event
     * @param pool The Pool in which the reserve will be initialized
     * @param input The needed parameters for the initialization
     */
    function executeInitReserve(IPool pool, ConfiguratorInputTypes.InitReserveInput calldata input) public {
        address yTokenProxyAddress = _initTokenWithProxy(
            input.yTokenImpl,
            abi.encodeCall(
                IInitializableYToken.initialize,
                (
                    pool,
                    input.treasury,
                    input.underlyingAsset,
                    input.incentivesController,
                    input.underlyingAssetDecimals,
                    input.yTokenName,
                    input.yTokenSymbol,
                    input.params
                )
            )
        );

        address variableDebtTokenProxyAddress = _initTokenWithProxy(
            input.variableDebtTokenImpl,
            abi.encodeCall(
                IInitializableDebtToken.initialize,
                (
                    pool,
                    input.underlyingAsset,
                    input.incentivesController,
                    input.underlyingAssetDecimals,
                    input.variableDebtTokenName,
                    input.variableDebtTokenSymbol,
                    input.params
                )
            )
        );

        pool.initReserve(
            input.underlyingAsset, yTokenProxyAddress, variableDebtTokenProxyAddress, input.interestRateStrategyAddress
        );

        DataTypes.ReserveConfigurationMap memory currentConfig = DataTypes.ReserveConfigurationMap(0);

        currentConfig.setDecimals(input.underlyingAssetDecimals);

        currentConfig.setActive(true);
        currentConfig.setPaused(false);
        currentConfig.setFrozen(false);

        pool.setConfiguration(input.underlyingAsset, currentConfig);

        emit IPoolConfigurator.ReserveInitialized(
            input.underlyingAsset, yTokenProxyAddress, variableDebtTokenProxyAddress, input.interestRateStrategyAddress
        );
    }

    /**
     * @notice Initialize a reserve by creating and initializing yToken and variable debt token
     * @dev Emits the `ReserveInitialized` event
     * @param pool The Pool in which the reserve will be initialized
     * @param input The needed parameters for the initialization
     */
    function executeInitERC1155Reserve(IPool pool, ConfiguratorInputTypes.InitERC1155ReserveInput calldata input)
        public
    {
        address nTokenProxyAddress = _initTokenWithProxy(
            input.nTokenImpl,
            abi.encodeCall(INToken.initialize, (address(pool), input.treasury, input.underlyingAsset, input.params))
        );

        pool.initERC1155Reserve(input.underlyingAsset, nTokenProxyAddress, input.configurationProvider);

        emit IPoolConfigurator.ERC1155ReserveInitialized(input.underlyingAsset, nTokenProxyAddress);
    }

    /**
     * @notice Updates the yToken implementation and initializes it
     * @dev Emits the `YTokenUpgraded` event
     * @param cachedPool The Pool containing the reserve with the yToken
     * @param input The parameters needed for the initialize call
     */
    function executeUpdateYToken(IPool cachedPool, ConfiguratorInputTypes.UpdateYTokenInput calldata input) public {
        DataTypes.ReserveData memory reserveData = cachedPool.getReserveData(input.asset);

        (,,, uint256 decimals,) = cachedPool.getConfiguration(input.asset).getParams();

        bytes memory encodedCall = abi.encodeCall(
            IInitializableYToken.initialize,
            (
                cachedPool,
                input.treasury,
                input.asset,
                input.incentivesController,
                uint8(decimals),
                input.name,
                input.symbol,
                input.params
            )
        );

        _upgradeTokenImplementation(reserveData.yTokenAddress, input.implementation, encodedCall);

        emit IPoolConfigurator.YTokenUpgraded(input.asset, reserveData.yTokenAddress, input.implementation);
    }

    /**
     * @notice Updates the nToken implementation and initializes it
     * @dev Emits the `NTokenUpgraded` event
     * @param cachedPool The Pool containing the reserve with the yToken
     * @param input The parameters needed for the initialize call
     */
    function executeUpdateNToken(IPool cachedPool, ConfiguratorInputTypes.UpdateNTokenInput calldata input) public {
        DataTypes.ERC1155ReserveData memory reserveData = cachedPool.getERC1155ReserveData(input.asset);

        bytes memory encodedCall =
            abi.encodeCall(INToken.initialize, (address(cachedPool), input.treasury, input.asset, input.params));

        _upgradeTokenImplementation(reserveData.nTokenAddress, input.implementation, encodedCall);

        emit IPoolConfigurator.NTokenUpgraded(input.asset, reserveData.nTokenAddress, input.implementation);
    }

    /**
     * @notice Updates the variable debt token implementation and initializes it
     * @dev Emits the `VariableDebtTokenUpgraded` event
     * @param cachedPool The Pool containing the reserve with the variable debt token
     * @param input The parameters needed for the initialize call
     */
    function executeUpdateVariableDebtToken(
        IPool cachedPool,
        ConfiguratorInputTypes.UpdateDebtTokenInput calldata input
    ) public {
        DataTypes.ReserveData memory reserveData = cachedPool.getReserveData(input.asset);

        (,,, uint256 decimals,) = cachedPool.getConfiguration(input.asset).getParams();

        bytes memory encodedCall = abi.encodeCall(
            IInitializableDebtToken.initialize,
            (
                cachedPool,
                input.asset,
                input.incentivesController,
                uint8(decimals),
                input.name,
                input.symbol,
                input.params
            )
        );

        _upgradeTokenImplementation(reserveData.variableDebtTokenAddress, input.implementation, encodedCall);

        emit IPoolConfigurator.VariableDebtTokenUpgraded(
            input.asset, reserveData.variableDebtTokenAddress, input.implementation
        );
    }

    /**
     * @notice Creates a new proxy and initializes the implementation
     * @param implementation The address of the implementation
     * @param initParams The parameters that is passed to the implementation to initialize
     * @return The address of initialized proxy
     */
    function _initTokenWithProxy(address implementation, bytes memory initParams) internal returns (address) {
        TransparentAdminUpgradeableProxy proxy =
            new TransparentAdminUpgradeableProxy(implementation, address(this), initParams);
        return address(proxy);
    }

    /**
     * @notice Upgrades the implementation and makes call to the proxy
     * @dev The call is used to initialize the new implementation.
     * @param proxyAddress The address of the proxy
     * @param implementation The address of the new implementation
     * @param  initParams The parameters to the call after the upgrade
     */
    function _upgradeTokenImplementation(address proxyAddress, address implementation, bytes memory initParams)
        internal
    {
        ITransparentAdminUpgradeableProxy proxy = ITransparentAdminUpgradeableProxy(proxyAddress);
        proxy.upgradeToAndCall(implementation, initParams);
    }
}
