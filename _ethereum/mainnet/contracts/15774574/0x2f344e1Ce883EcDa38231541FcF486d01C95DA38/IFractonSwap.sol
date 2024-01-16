// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IFractonSwap {
    function nftTax() external view returns(uint256);
    function swapFFTtoMiniNFT(address miniNFTAddress, uint256 miniNFTAmount) external returns(bool);
    function swapMiniNFTtoNFT(address nftAddr) external returns(bool);
    function NFTtoMiniNFT(address nftAddr) external view returns(address);
    function miniNFTtoFFT(address miniNFT) external view returns(address);
}