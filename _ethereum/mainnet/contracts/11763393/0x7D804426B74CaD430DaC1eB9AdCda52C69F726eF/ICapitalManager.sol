// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12; 

interface ICapitalManager {
    event PL(uint indexed tokenId, uint premium, uint payout, bool isOptionSale);
    event PayOption(address indexed account, uint amount);
    
    function BASE() external view returns (uint);
    function feeRate() external view returns (uint);

    function payOption(address to, uint premium) external;
    function receivePayout(address from, uint tokenId, uint premium, uint payout, bool isOptionSale) payable external;
    function unlockBalance(uint tokenId, uint premium) external;
    function refundGas(address account, uint amount) external;
}