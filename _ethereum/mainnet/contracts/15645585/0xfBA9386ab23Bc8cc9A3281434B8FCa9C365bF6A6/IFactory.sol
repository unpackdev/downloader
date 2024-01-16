// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IFactory {
    function createNewFreeBettingContract(
        address payable _owner,
        address payable _creator,
        address _tokenPool,
        uint256 _fee
    ) external returns (address);

    function createNewCommunityBettingContract(
        address payable _owner,
        address payable _creator,
        address _tokenPool,
        uint256 _fee
    ) external returns (address);

    function createNewStandardBettingContract(
        address payable _owner,
        address payable _creater,
        address _tokenPool,
        uint256 _rewardForWinner,
        uint256 _rewardForCreator,
        uint256 _decimal,
        uint256 _fee
    ) external returns (address);

    function createNewGuaranteedBettingContract(
        address payable _owner,
        address payable _creater,
        address _tokenPool,
        uint256 _rewardForWinner,
        uint256 _rewardForCreator,
        uint256 _decimal,
        uint256 _fee
    ) external returns (address);
}
