// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IX2Factory {
    function feeToken() external view returns (address);
    function feeReceiver() external view returns (address);
    function getFee(address market, uint256 amount) external view returns (uint256);
}
