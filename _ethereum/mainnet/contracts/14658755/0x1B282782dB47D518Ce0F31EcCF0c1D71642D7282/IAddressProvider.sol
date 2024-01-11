//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IAddressProvider {
    function get_address(uint256 index) external view returns (address);
}
