// SPDX-License-Identifier: J-J-J-JENGA!!!
pragma solidity ^0.7.4;

import "./IERC20.sol";
import "./IWrappedERC20Events.sol";

interface IWrappedERC20Multiple is IERC20, IWrappedERC20Events
{
    function depositTokens(address LPAddress, uint256 _amount) external returns (uint256 totalNFTsToGive);
}