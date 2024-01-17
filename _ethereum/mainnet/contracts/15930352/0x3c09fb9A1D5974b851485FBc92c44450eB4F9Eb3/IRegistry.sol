// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;

import "./ISettings.sol";


interface IRegistry is ISettings {
    function isGatewayAddress(address _account) external view returns (bool);

    function fallbackFee() external view returns (uint256);

    function localSettings(
        address _caller,
        uint256 _routerType
    )
        external
        view
        returns (LocalSettings memory)
    ;

    function sourceSettings(
        address _caller,
        uint256 _targetChainId,
        uint256 _gatewayType,
        uint256 _routerType,
        uint256 _vaultType
    )
        external
        view
        returns (SourceSettings memory)
    ;

    function targetSettings(
        uint256 _vaultType,
        uint256 _routerType
    )
        external
        view
        returns (TargetSettings memory)
    ;

    function fallbackSettings(
        uint256 _targetChainId,
        uint256 _vaultType
    )
        external
        view
        returns (FallbackSettings memory)
    ;

    function variableTokenClaimSettings(
        uint256 _vaultType
    )
        external
        view
        returns (VariableTokenClaimSettings memory)
    ;

    function messageFeeEstimateSettings(
        uint256 _gatewayType
    )
        external
        view
        returns (MessageFeeEstimateSettings memory)
    ;

    function localAmountCalculationSettings(
        address _caller
    )
        external
        view
        returns (LocalAmountCalculationSettings memory)
    ;

    function vaultAmountCalculationSettings(
        address _caller,
        uint256 _vaultType,
        uint256 _fromChainId,
        uint256 _toChainId
    )
        external
        view
        returns (VaultAmountCalculationSettings memory)
    ;

    function swapAmountLimits(
        uint256 _vaultType
    )
        external
        view
        returns (uint256 swapAmountMin, uint256 swapAmountMax)
    ;
}
