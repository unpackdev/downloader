//SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface IDeflector {
    function calculateBoostedBalance(address _user, uint256 _balance)
        external
        view
        returns (uint256);

    function calculateCost(
        address _user,
        address _token,
        uint256 _nextLevel
    ) external view returns (uint256);

    function updateLevel(
        address _user,
        address _token,
        uint256 _nextLevel,
        uint256 _balance
    ) external returns (uint256);
}
