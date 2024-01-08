// SPDX-License-Identifier: UNLICENSED
/// @title INumbersOnTapRender
/// @notice Renderer for Numbers on Tap (NFT Faucet)
/// @author CyberPnk <cyberpnk@numbersontaprender.cyberpnk.win>

pragma solidity ^0.8.0;

interface INumbersOnTapRender {
    function getImage(uint256 itemId) external view returns(bytes memory);

    function getTokenURI(uint256 itemId) external view returns (string memory);
}