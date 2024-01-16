// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IBettingFactory {
    function createNewBettingContract(
        address payable _owner,
        address payable _creater,
        address _tokenPool,
        uint256 _fee
    ) external returns (address);

    function createNewBettingContract(
        address payable _owner,
        address payable _creater,
        address _tokenPool,
        uint256 _rewardForWinner,
        uint256 _rewardForCreator,
        uint256 _decimal,
        uint256 _fee
    ) external returns (address);
}
