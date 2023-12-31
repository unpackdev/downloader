// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.19;

interface IFloridaManCardStaking {
    event Stake(address indexed _from, uint256 indexed _id, uint256 _quantity);
    event Unstake(address indexed _from, uint256 indexed _id, uint256 _quantity);

    function stakeBatch(address _for, uint256[] memory _ids, uint256[] memory _quantities) external;

    function distribute(uint256 _startIndex) external;
}
