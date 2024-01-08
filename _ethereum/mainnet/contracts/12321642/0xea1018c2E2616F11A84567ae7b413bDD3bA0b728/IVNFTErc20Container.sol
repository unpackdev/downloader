// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./IVNFT.sol";
import "./IUnderlyingContainer.sol";

interface IVNFTErc20Container is IVNFT, IUnderlyingContainer {
    function getUnderlyingAmount(uint256 units) external view returns (uint256 underlyingAmount);
    function getUnits(uint256 underlyingAmount) external view returns (uint256 units);
}