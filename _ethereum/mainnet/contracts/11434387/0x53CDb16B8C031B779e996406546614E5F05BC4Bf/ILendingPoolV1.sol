// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

interface ILendingPoolV1 {
    function getUserReserveData(address _reserve, address _user) external view returns (
        uint256, 
        uint256, 
        uint256, 
        uint256, 
        uint256, 
        uint256, 
        uint256, 
        uint256, 
        uint256, 
        bool
    );

    function repay(address _reserve, uint256 _amount, address payable _onBehalfOf) external payable;
    
    function getReserves() external returns (address[] memory);

    function getReserveData(address _reserve) external returns (
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        address,
        uint40
    );

}