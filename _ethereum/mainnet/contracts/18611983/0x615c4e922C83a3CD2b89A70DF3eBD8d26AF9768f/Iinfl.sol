// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

interface Iinfl {

    function addPayment() external payable;

    function emergencyWithdraw() external;

    function inflWithdraw() external;

    function setTokenAddress(address _token) external;

    function addInfl(address _infl, uint256 _percent) external;

    function deleteInfl(address infl) external;
}
