//SPDX-License-Identifier: MIT
pragma solidity =0.6.6;

import "./IUniswapV2Pair.sol";

/// Bond manager as seen by other managers
interface IBondManager {
    /// Called when new token is added in TokenManager
    /// @param syntheticTokenAddress The address of the synthetic token
    /// @param bondTokenAddress The address of the bond token
    function addBondToken(
        address syntheticTokenAddress,
        address bondTokenAddress
    ) external;

    /// Called when token is deleted in TokenManager
    /// @param syntheticTokenAddress The address of the synthetic token
    /// @param newOperator New operator for the bond token
    function deleteBondToken(address syntheticTokenAddress, address newOperator)
        external;

    function bondIndex(address syntheticTokenAddress)
        external
        returns (address);
}
