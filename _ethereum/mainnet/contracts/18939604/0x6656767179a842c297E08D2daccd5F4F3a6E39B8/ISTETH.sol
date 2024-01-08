// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "./IERC20.sol";


interface IStEth is IERC20 {
    function getPooledEthByShares(uint256 _sharesAmount) external returns(uint256);
    function getSharesByPooledEth(uint256 _ethAmount) external returns(uint256);
}
