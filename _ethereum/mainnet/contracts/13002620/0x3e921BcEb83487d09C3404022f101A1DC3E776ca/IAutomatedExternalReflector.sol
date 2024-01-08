// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAutomatedExternalReflector {
    function depositEth() external payable returns(bool);

    function logTransactionEvent(address from, address to) external returns(bool);
    function getRemainingPayeeCount() external view returns(uint256 count);
    function reflectRewards() external returns (bool allComplete);

    function enableReflections(bool enable) external;

    function isExcludedFromReflections(address ad) external view returns(bool excluded);
    function excludeFromReflections(address target, bool excluded) external;

    function updateTotalSupply(uint256 newTotalSupply) external;
}
