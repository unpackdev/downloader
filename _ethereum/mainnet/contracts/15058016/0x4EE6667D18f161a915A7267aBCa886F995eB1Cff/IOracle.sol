// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.11;

interface IOracle {
    /// @notice Returns the underlying price in purchase tokens.
    /// @dev Gets data from a Chainlink aggregator.
    function quote() external view returns (uint256);

    /// @notice Converts purchase token in value to the number of underlying out
    /// with a discount applied.
    function purchaseTokenToUnderlying(uint256 _purchaseTokenIn, uint256 _discount) external view returns (uint256);
}
