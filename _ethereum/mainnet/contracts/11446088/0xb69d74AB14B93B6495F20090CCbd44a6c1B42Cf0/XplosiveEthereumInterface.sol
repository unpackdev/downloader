// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

interface XplosiveEthereumInterface {
    //Public functions
    function maxScalingFactor() external view returns (uint256);
    function xETHScalingFactor() external view returns (uint256);
    //rebase permissioned
    function setTxFee(uint16 fee) external ;
    function setSellFee(uint16 fee) external ;
    function rebase(uint256 epoch, uint256 indexDelta, bool positive) external returns (uint256);
}
