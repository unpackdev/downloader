// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IMerkleDistributorCreator {
    // Returns the address of the merkleDistributor implementation.
    function distributorImpl() external view returns (address);

    // Returns the address of the proxy admin.
    function proxyAdmin() external view returns (address);

    // Set merkle distributor implementation address.
    function setDistributorImpl(address _distributorImpl) external;

    // Set proxy admin address.
    function setProxyAdmin(address _proxyAdmin) external;
}
