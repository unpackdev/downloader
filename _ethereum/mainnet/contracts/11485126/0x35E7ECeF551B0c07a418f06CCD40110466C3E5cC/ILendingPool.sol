// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface ILendingPool {
    event FlashLoanCompleted(
        address indexed _user,
        address indexed _receiver,
        address indexed _token,
        uint256 _amount,
        uint256 _totalFee
    );
    function flashLoan(
        address _receiver, 
        address _token, 
        uint256 _amount, 
        bytes memory _params
    ) external;

    function getReservesAvailable(address _token) external view returns (uint256);
    function getFeeForAmount(address _token, uint256 _amount) external view returns (uint256);
}