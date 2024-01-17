// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./LibMintpass.sol";

interface IABBLegacy {
    function mint(address minter, uint256 quantity) external payable;

    function fiatMint(address minter, uint256 quantity) external;

    function redeemBottle(uint256 tokenId) external payable;

    function allowlistMint(
        uint256 quantity,
        LibMintpass.Mintpass memory mintpass,
        bytes memory mintpassSignature
    ) external payable;
}

/** created with bowline.app **/
