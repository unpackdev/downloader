// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;


interface IOracle {
    /// @notice price used to open loans, typically a manipulation-resistant price.
    function getOpenPrice( bytes calldata parameters) external view returns (uint256 );

    /// @notice price used to liquidate loans, typically spot price. 
    function getClosePrice( bytes calldata parameters) external view returns (uint256 );

}
