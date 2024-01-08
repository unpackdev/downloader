// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IGateway.sol";

interface IGatewayRegistry {
    /// @notice Returns the Gateway contract for the given RenERC20
    ///         address.
    ///
    /// @param _tokenAddress The address of the RenERC20 contract.
    function getGatewayByToken(address _tokenAddress) external view returns (IGateway);
}
