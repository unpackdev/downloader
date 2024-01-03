// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

interface IBundle {
    
    function underlyingBalanceInBundle() external view returns (uint256);
    function underlyingBalanceWithInvestment() external view returns (uint256);
    
    // function governance() external view returns (address);
    // function controller() external view returns (address);
    function getUnderlying() external view returns (address);
    function getVault() external view returns (address);

    function addStrategy(address _strategy, uint256 riskScore, uint256 weightage) external;
    // function removeStrategy(address _strategy) external;
    
    function withdrawAll() external;
    function withdraw(uint256 underlyingAmountToWithdraw, address holder) external returns (uint256);

    function depositArbCheck() external view returns(bool);

    function doHardWork() external;
    function rebalance() external;
}
