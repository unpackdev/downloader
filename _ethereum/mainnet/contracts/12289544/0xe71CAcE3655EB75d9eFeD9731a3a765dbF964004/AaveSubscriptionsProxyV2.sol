pragma solidity ^0.6.0;

import "./ProxyPermission.sol";
import "./IAaveSubscription.sol";

/// @title SubscriptionsProxy handles authorization and interaction with the Subscriptions contract
contract AaveSubscriptionsProxyV2 is ProxyPermission {

    string public constant NAME = "AaveSubscriptionsProxyV2";

    address public constant AAVE_SUBSCRIPTION_ADDRESS = 0x6B25043BF08182d8e86056C6548847aF607cd7CD;
    address public constant AAVE_MONITOR_PROXY = 0x380982902872836ceC629171DaeAF42EcC02226e;

    /// @notice Calls subscription contract and creates a DSGuard if non existent
    /// @param _minRatio Minimum ratio below which repay is triggered
    /// @param _maxRatio Maximum ratio after which boost is triggered
    /// @param _optimalRatioBoost Ratio amount which boost should target
    /// @param _optimalRatioRepay Ratio amount which repay should target
    /// @param _boostEnabled Boolean determing if boost is enabled
    function subscribe(
        uint128 _minRatio,
        uint128 _maxRatio,
        uint128 _optimalRatioBoost,
        uint128 _optimalRatioRepay,
        bool _boostEnabled
    ) public {
        givePermission(AAVE_MONITOR_PROXY);
        IAaveSubscription(AAVE_SUBSCRIPTION_ADDRESS).subscribe(
            _minRatio, _maxRatio, _optimalRatioBoost, _optimalRatioRepay, _boostEnabled);
    }

    /// @notice Calls subscription contract and updated existing parameters
    /// @dev If subscription is non existent this will create one
    /// @param _minRatio Minimum ratio below which repay is triggered
    /// @param _maxRatio Maximum ratio after which boost is triggered
    /// @param _optimalRatioBoost Ratio amount which boost should target
    /// @param _optimalRatioRepay Ratio amount which repay should target
    /// @param _boostEnabled Boolean determing if boost is enabled
    function update(
        uint128 _minRatio,
        uint128 _maxRatio,
        uint128 _optimalRatioBoost,
        uint128 _optimalRatioRepay,
        bool _boostEnabled
    ) public {
        IAaveSubscription(AAVE_SUBSCRIPTION_ADDRESS).subscribe(_minRatio, _maxRatio, _optimalRatioBoost, _optimalRatioRepay, _boostEnabled);
    }

    /// @notice Calls the subscription contract to unsubscribe the caller
    function unsubscribe() public {
        removePermission(AAVE_MONITOR_PROXY);
        IAaveSubscription(AAVE_SUBSCRIPTION_ADDRESS).unsubscribe();
    }
}
