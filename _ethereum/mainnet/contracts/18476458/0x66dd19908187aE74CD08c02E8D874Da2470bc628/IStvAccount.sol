// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./IVault.sol";

interface IStvAccount {
    function stvInfo() external view returns (IVault.StvInfo memory);
    function stvBalance() external view returns (IVault.StvBalance memory);
    function investorInfo(address investorAccount) external view returns (IVault.InvestorInfo memory);
    function investors() external view returns (address[] memory);
    function getInvestors() external view returns (address[] memory);
    function totalTradeTokenReceivedAfterOpen(address token) external view returns (uint96);
    function totalTradeTokenUsedForClose(address token) external view returns (uint96);
    function execute(address adapter, bytes calldata data, uint256 ethToSend) external payable;
    function createStv(IVault.StvInfo memory stv) external;
    function deposit(address investorAccount, uint96 amount, bool isFirstDeposit) external;
    function liquidate() external;
    function execute(uint96 amount, address tradeToken, uint96 totalReceived, bool isOpen) external;
    function distribute(uint96 totalRemainingAfterDistribute, uint96 mFee, uint96 pFee) external;
    function distributeOut(bool isCancel, uint256 indexFrom, uint256 indexTo) external;
    function updateStatus(IVault.StvStatus status) external;
    function cancel() external;
}
