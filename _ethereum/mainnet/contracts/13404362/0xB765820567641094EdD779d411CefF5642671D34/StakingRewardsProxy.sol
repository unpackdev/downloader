pragma solidity 0.5.12;
pragma experimental ABIEncoderV2;

import "./AdminUpgradeabilityProxy.sol";

contract StakingRewardsProxy is AdminUpgradeabilityProxy {
    constructor(address _logic, address _proxyAdmin)
        public
        AdminUpgradeabilityProxy(
            _logic,
            _proxyAdmin,
            ""
        )
    {}
}