pragma solidity ^0.6.0;

import "./DSGuard.sol";
import "./DSAuth.sol";
import "./ConstantAddresses.sol";

contract SubscriptionsInterface {
    function subscribe(uint _cdpId, uint128 _minRatio, uint128 _maxRatio, uint128 _optimalBoost, uint128 _optimalRepay) external {}
    function unsubscribe(uint _cdpId) external {}
}

/// @title SubscriptionsProxy handles authorization and interaction with the Subscriptions contract
contract SubscriptionsProxy is ConstantAddresses {

    address public constant MONITOR_PROXY_ADDRESS = 0x93Efcf86b6a7a33aE961A7Ec6C741F49bce11DA7;

    function subscribe(uint _cdpId, uint128 _minRatio, uint128 _maxRatio, uint128 _optimalRatioBoost, uint128 _optimalRatioRepay, address _subscriptions) public {

        address currAuthority = address(DSAuth(address(this)).authority());
        DSGuard guard = DSGuard(currAuthority);

        if (currAuthority == address(0)) {
            guard = DSGuardFactory(FACTORY_ADDRESS).newGuard();
            DSAuth(address(this)).setAuthority(DSAuthority(address(guard)));
        }

        guard.permit(MONITOR_PROXY_ADDRESS, address(this), bytes4(keccak256("execute(address,bytes)")));

        SubscriptionsInterface(_subscriptions).subscribe(_cdpId, _minRatio, _maxRatio, _optimalRatioBoost, _optimalRatioRepay);
    }

    function update(uint _cdpId, uint128 _minRatio, uint128 _maxRatio, uint128 _optimalRatioBoost, uint128 _optimalRatioRepay, address _subscriptions) public {
        SubscriptionsInterface(_subscriptions).subscribe(_cdpId, _minRatio, _maxRatio, _optimalRatioBoost, _optimalRatioRepay);
    }

    function unsubscribe(uint _cdpId, address _subscriptions) public {
        SubscriptionsInterface(_subscriptions).unsubscribe(_cdpId);
    }
}
