// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.7;

import "./TransparentUpgradeableProxy.sol";
import "./ERC1967Proxy.sol";

import "./ManageableProxy.sol";
import "./AnkrTokenStaking.sol";

contract AnkrTokenStakingProxy is ManageableProxy {

    constructor(IStakingConfig stakingConfig, IERC20 ankrToken) ManageableProxy(
        stakingConfig, _deployDefault(),
        abi.encodeWithSelector(AnkrTokenStaking.initialize.selector, stakingConfig, ankrToken)
    ) {
    }

    function _deployDefault() internal returns (address) {
        AnkrTokenStaking impl = new AnkrTokenStaking{
        salt : keccak256("AnkrTokenStakingV0")
        }();
        return address(impl);
    }
}
