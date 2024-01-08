// SPDX-License-Identifier: ISC

pragma solidity 0.6.12;

import "./StakingProxyBeacon.sol";
import "./StakingProxyProxy.sol";

import "./Ownable.sol";

contract StakingFactory is Ownable {
    address public stakingProxyBeacon;
    address payable[] public stakingProxyProxies;

    constructor(address _stakingProxyBeacon) public {
        stakingProxyBeacon = _stakingProxyBeacon;
    }

    function deployProxy() external onlyOwner returns (address) {
        StakingProxyProxy proxy = new StakingProxyProxy(stakingProxyBeacon);
        stakingProxyProxies.push(address(proxy));
        return address(proxy);
    }

    function getStakingProxyProxiesLength() external view returns (uint256) {
        return stakingProxyProxies.length;
    }
}
