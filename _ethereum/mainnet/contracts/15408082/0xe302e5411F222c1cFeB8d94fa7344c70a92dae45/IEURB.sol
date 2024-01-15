// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";

interface IEURB is IERC20{
    function _feePercentage() external view returns(uint256);
    function decimals() external view returns(uint8);
    function isExcludedFromFee(address) external view returns(bool);
    function isReceiverExcludedFromFee(address) external view returns(bool);
    function isTransactionExcludedFromFee(address,address) external view returns(bool);
    function getTransactionFee(address,address,uint256) external view returns(uint256);
    function mint(address,uint256) external;
    function burn(uint256) external;
}