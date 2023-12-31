// SPDX-License-Identifier: CC0 1.0 Universal

//                 ____    ____
//                /\___\  /\___\
//       ________/ /   /_ \/___/
//      /\_______\/   /__\___\
//     / /       /       /   /
//    / /   /   /   /   /   /
//   / /   /___/___/___/___/
//  / /   /
//  \/___/

pragma solidity 0.8.19;

import "./Wawa.sol";

interface IWawaNFT {
    function getWawa(
        address to,
        uint256 tokenId,
        string memory tokenURI,
        Faction faction,
        Trait memory trait,
        uint8 pet,
        bytes32 gene
    )
        external
        payable;

    function totalSupply() external view returns (uint256);
}
