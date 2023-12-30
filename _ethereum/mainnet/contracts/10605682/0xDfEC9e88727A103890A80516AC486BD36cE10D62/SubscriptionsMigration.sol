pragma solidity ^0.6.0;

import "./MCDMonitorProxy.sol";
import "./ISubscriptions.sol";
import "./Manager.sol";
import "./Auth.sol";
import "./ProxyPermission.sol";
import "./DSAuth.sol";
import "./DSGuard.sol";


contract SubscriptionsMigration is Auth {

	// proxyPermission address
	address public proxyPermission;


	address public monitorProxyAddress = 0x93Efcf86b6a7a33aE961A7Ec6C741F49bce11DA7;
	// v1 monitor proxy
	MCDMonitorProxy public monitorProxyContract = MCDMonitorProxy(monitorProxyAddress);
	// v1 subscriptions contract
	ISubscriptions public subscriptionsContract = ISubscriptions(0x83152CAA0d344a2Fd428769529e2d490A88f4393);
	// v2 subscriptions proxy with "migrate" method
	address public subscriptionsProxyV2address = 0xd6f2125bF7FE2bc793dE7685EA7DEd8bff3917DD;
	// v2 subscriptions address (needs to be passed to migrate method)
	address public subscriptionsV2address = 0xC45d4f6B6bf41b6EdAA58B01c4298B8d9078269a;
	// v1 subscriptions address
	address public subscriptionsV1address = 0x83152CAA0d344a2Fd428769529e2d490A88f4393;
	// v1 subscriptions proxy address
	address public subscriptionsProxyV1address = 0xA5D33b02dBfFB3A9eF26ec21F15c43BdB53EB455;
	// manager to check if owner is valid
	Manager public manager = Manager(0x5ef30b9986345249bc32d8928B7ee64DE9435E39);

	constructor(address _proxyPermission) public {
		proxyPermission = _proxyPermission;
	}

	function migrate(uint[] memory _cdps) public onlyAuthorized {

		for (uint i=0; i<_cdps.length; i++) {
			if (_cdps[i] == 0) continue;

			bool sub;
			uint minRatio;
			uint maxRatio;
			uint optimalRepay;
			uint optimalBoost;
			address cdpOwner;
			uint collateral;

			// get data for specific cdp
			(sub, minRatio, maxRatio, optimalRepay, optimalBoost, cdpOwner, collateral,) = subscriptionsContract.getSubscribedInfo(_cdps[i]);

			// if user is not the owner anymore, we will have to unsub him manually
			if (cdpOwner != _getOwner(_cdps[i])) {
				continue;
			} 

			// call migrate method on SubscriptionsProxyV2 through users DSProxy if cdp is subbed and have collateral
			if (sub && collateral > 0) {
				monitorProxyContract.callExecute(cdpOwner, subscriptionsProxyV2address, abi.encodeWithSignature("migrate(uint256,uint128,uint128,uint128,uint128,bool,bool,address)", _cdps[i], minRatio, maxRatio, optimalBoost, optimalRepay, true, true, subscriptionsV2address));
			} else {
				// if cdp is subbed but no collateral, just unsubscribe user
				if (sub) {
					_unsubscribe(_cdps[i], cdpOwner);
				}
			}

			// don't remove authority here because we wouldn't be able to unsub or migrate if user have more than one cdp
		}
	}

	function removeAuthority(address[] memory _users) public onlyAuthorized {

		for (uint i=0; i<_users.length; i++) {
			_removeAuthority(_users[i]);
		}
	}

	function _unsubscribe(uint _cdpId, address _cdpOwner) internal onlyAuthorized {
		address currAuthority = address(DSAuth(_cdpOwner).authority());
		// if no authority return
		if (currAuthority == address(0)) return;
        DSGuard guard = DSGuard(currAuthority);

        // if we don't have permission on specific authority, return
        if (!guard.canCall(monitorProxyAddress, _cdpOwner, bytes4(keccak256("execute(address,bytes)")))) return;

        // call unsubscribe on v1 proxy through users DSProxy
		monitorProxyContract.callExecute(_cdpOwner, subscriptionsProxyV1address, abi.encodeWithSignature("unsubscribe(uint256,address)", _cdpId, subscriptionsV1address));
	}

	function _removeAuthority(address _cdpOwner) internal onlyAuthorized {

		address currAuthority = address(DSAuth(_cdpOwner).authority());
		// if no authority return
		if (currAuthority == address(0)) return;
        DSGuard guard = DSGuard(currAuthority);

        // if we don't have permission, that means its already removed
        if (!guard.canCall(monitorProxyAddress, _cdpOwner, bytes4(keccak256("execute(address,bytes)")))) return;

		monitorProxyContract.callExecute(_cdpOwner, proxyPermission, abi.encodeWithSignature("removePermission(address)", monitorProxyAddress));
	}

	/// @notice Returns an address that owns the CDP
    /// @param _cdpId Id of the CDP
    function _getOwner(uint _cdpId) internal view returns(address) {
        return manager.owns(_cdpId);
    }
}