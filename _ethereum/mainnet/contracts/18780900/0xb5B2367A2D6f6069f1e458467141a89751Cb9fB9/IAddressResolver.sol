// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

interface IAddressResolver {
    error UnmatchedInputs();

    event AddressImported(bytes32 name, address destination);

    function getAddress(bytes32 name, string calldata reason) external view returns (address);

    function getAddress(bytes32 name) external view returns (address);

    function getAddresses() external view returns (address[] memory);

    function getNames() external view returns (bytes32[] memory);
}
