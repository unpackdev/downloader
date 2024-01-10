// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IWhatSwapV1Factory {
    function lpFee() external returns (uint);
    function feeTo() external returns (address);
    function getFlashLoanFeesInBips() external returns (uint, uint);
    function totalPairs() external view returns (uint);
    function getPair(address tokenAddress) external view returns (address pair);

    function createPair(address tokenAddress) external returns (address pair);
    function createPairWithAddExactEthLP(address tokenAddress, uint tokenAmountMin, address to, uint deadline) payable external returns (address pair, uint lpAmount);

    event lpFeeUpdated(uint previousFee, uint newFee);
    event PairCreated(address indexed tokenAddress, address pair, uint);
    event flashLoanFeeUpdated(uint flashloan_fee_total, uint flashloan_fee_protocol);
}