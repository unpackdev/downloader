// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface ISFIRewarder {
    function supplyRewards(address to, uint256 amount) external;
}
