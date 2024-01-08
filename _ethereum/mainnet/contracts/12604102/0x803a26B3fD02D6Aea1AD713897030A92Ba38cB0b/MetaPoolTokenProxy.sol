// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "./TransparentUpgradeableProxy.sol";

contract MetaPoolTokenProxy is TransparentUpgradeableProxy {
    constructor(
        address _logic,
        address _proxyAdmin,
        address _addressRegistry
    )
        public
        TransparentUpgradeableProxy(
            _logic,
            _proxyAdmin,
            abi.encodeWithSignature(
                "initialize(address,address)",
                _proxyAdmin,
                _addressRegistry
            )
        )
    {} // solhint-disable no-empty-blocks
}
