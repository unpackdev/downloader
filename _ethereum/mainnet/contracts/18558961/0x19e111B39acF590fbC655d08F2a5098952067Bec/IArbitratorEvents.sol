// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IArbitratorEvents {
    /*////////////////////////////////////////////////////////////// 
                                 Events                              
    //////////////////////////////////////////////////////////////*/

    event Created(
        uint256 indexed id,
        uint256 indexed bet,
        address indexed asset
    );

    event Joined(uint256 indexed id, address indexed participant);

    event Left(uint256 indexed id, address indexed participant);

    event Played(uint256 indexed id, address indexed participant, uint128 bet);

    event Folded(uint256 indexed id, address indexed participant);

    event Claimed(
        uint256 indexed id,
        address indexed participant,
        address indexed asset,
        uint128 amount
    );

    event Started(uint256 indexed id);
}
