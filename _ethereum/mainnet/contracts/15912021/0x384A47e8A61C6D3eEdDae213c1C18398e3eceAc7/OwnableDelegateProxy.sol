/*

  WyvernOwnableDelegateProxy

*/

pragma solidity 0.4.23;

import "./ProxyRegistry.sol";
import "./AuthenticatedProxy.sol";
import "./OwnedUpgradeabilityProxy.sol";

contract OwnableDelegateProxy is OwnedUpgradeabilityProxy {

    constructor(address owner, address initialImplementation, bytes calldata)
        public
    {
        setUpgradeabilityOwner(owner);
        _upgradeTo(initialImplementation);
        require(initialImplementation.delegatecall(calldata));
    }

}
