// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "./TransparentUpgradeableProxy.sol";

contract GovernanceTokenProxy is TransparentUpgradeableProxy {
    constructor(
        address _logic,
        address _proxyAdmin,
        uint256 _totalSupply
    )
        public
        TransparentUpgradeableProxy(
            _logic,
            _proxyAdmin,
            abi.encodeWithSignature(
                "initialize(address,uint256)",
                _proxyAdmin,
                _totalSupply
            )
        )
    {} // solhint-disable no-empty-blocks
}
