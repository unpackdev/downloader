/*
    SPDX-License-Identifier: Apache-2.0

    Copyright 2021 Reddit, Inc

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.8.9;

import "./ProxyAdmin.sol";
import "./Create2.sol";
import "./TransparentUpgradeableProxy.sol";

contract ProxyAdmin2 is ProxyAdmin {

    event ProxyDeployed(address proxy);

    function deployProxy(bytes32 salt, address impl, bytes calldata args) public returns (address) {
        bytes memory proxyByteCodeWithArgs = _getProxyByteCodeWithArgs(impl, args);
        address proxyAddress = Create2.deploy(0, salt, proxyByteCodeWithArgs);
        emit ProxyDeployed(proxyAddress);
        return proxyAddress;
    }

    function computeProxyAddress(bytes32 salt, address impl, bytes calldata args) public view returns (address) {
        bytes memory proxyByteCodeWithArgs = _getProxyByteCodeWithArgs(impl, args);
        return Create2.computeAddress(salt, keccak256(proxyByteCodeWithArgs));
    }

    function _getProxyByteCodeWithArgs(address impl, bytes calldata args) internal view returns (bytes memory) {
        bytes memory proxyByteCode = type(TransparentUpgradeableProxy).creationCode;
        return abi.encodePacked(proxyByteCode, abi.encode(impl, address(this), args));
    }
}
