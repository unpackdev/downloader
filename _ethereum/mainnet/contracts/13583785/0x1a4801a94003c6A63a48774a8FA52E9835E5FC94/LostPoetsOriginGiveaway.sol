// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @artist: Pak
/// @author: manifold.xyz

import "./AdminControl.sol";
import "./IERC1155.sol";

import "./ILostPoets.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                           //
//  `7MMF'        .g8""8q.    .M"""bgd MMP""MM""YMM `7MM"""Mq.   .g8""8q. `7MM"""YMM MMP""MM""YMM  .M"""bgd  //
//    MM        .dP'    `YM. ,MI    "Y P'   MM   `7   MM   `MM..dP'    `YM. MM    `7 P'   MM   `7 ,MI    "Y  //
//    MM        dM'      `MM `MMb.          MM        MM   ,M9 dM'      `MM MM   d        MM      `MMb.      //
//    MM        MM        MM   `YMMNq.      MM        MMmmdM9  MM        MM MMmmMM        MM        `YMMNq.  //
//    MM      , MM.      ,MP .     `MM      MM        MM       MM.      ,MP MM   Y  ,     MM      .     `MM  //
//    MM     ,M `Mb.    ,dP' Mb     dM      MM        MM       `Mb.    ,dP' MM     ,M     MM      Mb     dM  //
//  .JMMmmmmMMM   `"bmmd"'   P"Ybmmd"     .JMML.    .JMML.       `"bmmd"' .JMMmmmmMMM   .JMML.    P"Ybmmd"   //
//                                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////

contract LostPoetsOriginGiveaway is AdminControl {

    address private _lostPoetsAddress;
    uint256 private _lastOriginMint;

    constructor(address lostPoetsAddress, uint256 lastOriginMint) {
        _lostPoetsAddress = lostPoetsAddress;
        _lastOriginMint = lastOriginMint;
    }

    function drop(address[2] memory recipients, uint256[2] memory tokenIds) external adminRequired {
        require(block.timestamp >= _lastOriginMint + 86400, "Minimum time not met");

        _lastOriginMint += 86400;
        address[] memory recipients_ = new address[](2);
        recipients_[0] = recipients[0];
        recipients_[1] = recipients[1];
        uint256[] memory tokenIds_ = new uint256[](2);
        tokenIds_[0] = tokenIds[0];
        tokenIds_[1] = tokenIds[1];
        ILostPoets(_lostPoetsAddress).mintOrigins(recipients_, tokenIds_);
    }

}