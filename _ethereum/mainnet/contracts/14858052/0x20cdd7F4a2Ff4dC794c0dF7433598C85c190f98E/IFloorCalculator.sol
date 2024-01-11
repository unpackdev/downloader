// SPDX-License-Identifier: J-J-J-JENGA!!!

pragma solidity ^0.7.4;
import "./IERC20.sol";

interface IFloorCalculator
{
    function calculateSubFloorPETH(IERC20 wrappedToken, IERC20 backingToken) external view returns (uint256);
    function calculateSubFloorCircleNFT(IERC20[] memory wrappedTokens, IERC20 backingToken) external view returns ( uint256);
}
