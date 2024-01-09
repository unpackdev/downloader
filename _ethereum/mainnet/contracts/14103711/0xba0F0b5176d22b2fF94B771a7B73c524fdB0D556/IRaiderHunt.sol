//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IRaiderHunt {
    function isStaker(address _address, uint256 _tokenId) external view returns (bool);
}