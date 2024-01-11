// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;
import "./YieldsterVaultProxy.sol";

interface IProxyCreationCallback {
    function proxyCreated(
        YieldsterVaultProxy proxy,
        address _mastercopy,
        bytes calldata initializer,
        uint256 saltNonce
    ) external;
}
