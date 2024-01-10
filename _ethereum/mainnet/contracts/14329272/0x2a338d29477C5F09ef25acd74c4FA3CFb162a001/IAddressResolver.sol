// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

interface IAddressResolver {
    function getAddress(bytes32 name) external view returns (address);

    function getSynth(bytes32 key) external view returns (address);

    function requireAndGetAddress(bytes32 name, string calldata reason) external view returns (address);
}
