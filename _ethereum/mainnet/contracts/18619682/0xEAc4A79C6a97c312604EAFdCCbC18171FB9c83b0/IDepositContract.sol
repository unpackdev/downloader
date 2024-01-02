// INSTRUCTIONS : Contains methods that will be used by the ROUTER and GENERATOR contracts.
// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IDepositContract {
    function isContractEligible(address _clientAddress, address _contractAddress) external view returns (bool);

    function isMinimumBalanceReached(address _clientAddress) external view returns (bool);

    function checkMinBalance(address _clientAddress) external view returns (uint256);

    function checkClientFund(address _clientAddress) external view returns (uint256);

    function collectFund(address _clientAddress, uint256 _amount) external;
}
