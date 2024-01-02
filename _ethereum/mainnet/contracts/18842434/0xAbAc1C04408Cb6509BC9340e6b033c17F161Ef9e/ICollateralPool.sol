// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICollateralPool{
    function userProvideLiquidity(address to, uint amount1) external;
    function collat_XSD() external returns(uint);
    function mintAlgorithmicXSD(uint256 bankx_amount_d18, uint256 XSD_out_min) external;
    function collatDollarBalance() external returns(uint);
}

