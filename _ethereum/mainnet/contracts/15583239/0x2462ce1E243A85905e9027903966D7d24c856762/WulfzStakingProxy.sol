// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface Wulfz {
    function getStakedWulfz(address owner) external view returns (uint256[] memory);
}

contract WulfzStakingProxy {
    function balanceOf(address owner) public view returns (uint256) {
        uint256[] memory tokenIds = Wulfz(address(0x3864b787e498BF89eDFf0ED6258393D4CF462855)).getStakedWulfz(owner);
        uint256 balance = tokenIds.length;
        return balance;
    }
}