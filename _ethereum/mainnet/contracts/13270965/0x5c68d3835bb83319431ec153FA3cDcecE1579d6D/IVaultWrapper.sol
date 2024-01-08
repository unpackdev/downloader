// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.2;


interface IVaultWrapper {
    function initialize(address _vault) external;
    function apiVersion() external view returns(string memory);
}
