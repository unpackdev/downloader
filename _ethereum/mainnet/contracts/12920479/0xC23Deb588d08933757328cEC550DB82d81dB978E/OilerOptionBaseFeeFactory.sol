// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;
pragma abicoder v2;

import "./OilerOptionBaseFee.sol";
import "./OilerOptionBaseFactory.sol";

contract OilerOptionBaseFeeFactory is OilerOptionBaseFactory {
    constructor(
        address _factoryOwner,
        address _registryAddress,
        address _bRouter,
        address _optionLogicImplementation
    ) OilerOptionBaseFactory(_factoryOwner, _registryAddress, _bRouter, _optionLogicImplementation) {}

    function createOption(
        uint256 _strikePrice,
        uint256 _expiryTS,
        bool _put,
        address _collateral,
        uint256 _collateralToPushIntoAmount,
        uint256 _optionsToPushIntoPool
    ) external override onlyOwner returns (address optionAddress) {
        address option = _createOption();
        OilerOptionBaseFee(option).init(_strikePrice, _expiryTS, _put, _collateral);
        _pullInitialLiquidityCollateral(_collateral, _collateralToPushIntoAmount);
        _initializeOptionsPool(
            OptionInitialLiquidity(_collateral, _collateralToPushIntoAmount, option, _optionsToPushIntoPool)
        );
        registry.registerOption(option, "F");
        emit Created(option, "F");
        return option;
    }
}
