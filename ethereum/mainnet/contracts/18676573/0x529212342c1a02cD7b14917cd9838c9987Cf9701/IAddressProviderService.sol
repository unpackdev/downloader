// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

interface IAddressProviderService {
    /// @notice Returns the address of the AddressProvider
    function addressProviderTarget() external view returns (address);
}
