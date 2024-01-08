// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

contract Events {
    event LogClaimed(
        address[] assets,
        uint256 amt,
        uint256 getId,
        uint256 setId
    );
}
