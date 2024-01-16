// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IOneHiTableLogic {
    function initialize(address _controller, address fftAddr) external;
    function claimTreasure(address player, address nftAddr, uint256 tokenId) external returns(bool);
    function swapNFT(address fractonSwapAddr, address fftAddr, address miniNFTAddr, uint256 miniNFTAmount,
        address nftAddr) external;
}
