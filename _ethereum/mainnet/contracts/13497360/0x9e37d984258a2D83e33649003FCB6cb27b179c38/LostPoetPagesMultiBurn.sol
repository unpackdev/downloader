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

contract LostPoetPagesMultiBurn is AdminControl {

    address private _erc1155BurnAddress;
    address private _lostPoetsAddress;

    constructor(address lostPoetPagesAddress, address lostPoetsAddress) {
        _erc1155BurnAddress = lostPoetPagesAddress;
        _lostPoetsAddress = lostPoetsAddress;
    }

    function updateERC1155BurnAddress(address erc1155BurnAddress) external adminRequired {
        _erc1155BurnAddress = erc1155BurnAddress;
    }

    function multiBurn(uint256 burnTokenId, uint256 amount, bytes calldata data) external {
        require(IERC1155(_erc1155BurnAddress).isApprovedForAll(msg.sender, address(this)), "No permissions");
        require(IERC1155(_erc1155BurnAddress).balanceOf(msg.sender, burnTokenId) >= amount, "Insufficient quantity");

        for (uint i = 0; i < amount; i++) {
            try IERC1155(_erc1155BurnAddress).safeTransferFrom(msg.sender, _lostPoetsAddress, burnTokenId, 1, data) {
            } catch Error(string memory reason) {
              if (keccak256(abi.encodePacked(reason)) == keccak256(abi.encodePacked("ERC1155: transfer to non ERC1155Receiver implementer"))) break;
              revert(reason);
            }
        }
    }

}