// SPDX-License-Identifier: MIT
// https://github.com/wighawag/hardhat-deploy/blob/master/solc_0.7/proxy/EIP173ProxyWithReceive.sol
pragma solidity 0.7.5;

import "./EIP173Proxy.sol";

///@notice Proxy implementing EIP173 for ownership management that accept ETH via receive
contract EIP173ProxyWithReceive is EIP173Proxy {
    constructor(
        address implementationAddress,
        bytes memory data,
        address ownerAddress
    ) payable EIP173Proxy(implementationAddress, data, ownerAddress) {}

    receive() external payable {}
}
