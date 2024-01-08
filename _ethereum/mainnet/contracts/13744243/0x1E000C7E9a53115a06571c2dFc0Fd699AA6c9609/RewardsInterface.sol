//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface RewardsInterface {
    function mint(address owner, uint256 amount) external;

    function burnFrom(address from, uint256 amount) external;
}
