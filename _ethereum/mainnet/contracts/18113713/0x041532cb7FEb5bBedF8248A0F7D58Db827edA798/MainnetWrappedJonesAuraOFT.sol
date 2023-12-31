// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./UpgradeableProxyOFT.sol";

contract MainnetWrappedJonesAuraOFT is UpgradeableProxyOFT {
    function __initwjAuraProxyOFT(address _lzEndpoint, address _token) external initializer {
        __initProxyApp(_lzEndpoint, _token);
        __Ownable_init();
    }
}
