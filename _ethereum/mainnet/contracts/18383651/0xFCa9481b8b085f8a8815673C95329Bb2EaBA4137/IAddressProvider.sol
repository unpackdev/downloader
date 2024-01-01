// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IAddressProvider {
    function get_registry() external view returns (address);

    function max_id() external view returns (uint256);

    function get_address(uint256 _id) external view returns (address);
}
