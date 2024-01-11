// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.4.22 <0.9.0;

interface IAddressesProvider {
    function setTokenDistributor(address) external;

    function getTokenDistributor() external view returns (address);

    function owner() external view returns (address);
}
