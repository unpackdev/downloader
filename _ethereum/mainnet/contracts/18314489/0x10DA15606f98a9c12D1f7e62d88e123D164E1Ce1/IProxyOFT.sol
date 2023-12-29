// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./IComposableOFTCoreUpgradeable.sol";

interface IProxyOFT is IComposableOFTCoreUpgradeable {
    function getProxyOFTOf(uint16 chainId_) external view returns (address _proxyOFT);
}
