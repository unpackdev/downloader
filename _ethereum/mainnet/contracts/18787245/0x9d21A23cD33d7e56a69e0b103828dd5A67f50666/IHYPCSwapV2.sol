// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./IERC721.sol";

/// @notice Interface for the HYPCSwap.sol contract.
interface IHYPCSwapV2 is IERC721 {
    /**
     * Accesses the addNFT function so that the CHYPC contract can
     * add the newly created NFT into this contract.
     */

    function addRootTokens(uint256 tokens) external;

    function splitHeldToken(uint256 level, uint256 skipLevels) external;

    function swapV2(uint256 level) external;

    function redeem(uint256 tokenNumber) external;

    function assignNumber(uint256 tokenNumber, uint256 targetNumber) external;

    function assignString(uint256 tokenNumber, string memory data) external;

    function burn(uint256 tokenNumber, string memory data) external;

    function assign(uint256 tokenNumber, string memory data) external;

    function swap() external;


    function getAssignment(uint256 tokenNumber) external view returns (string memory);
    function getAssignmentNumber(uint256 tokenNumber) external view returns (uint256);
    function getAssignmentString(uint256 tokenNumber) external view returns (string memory);



    function getBurnData(uint256 tokenNumber) external view returns (string memory);

    function getAvailableToken(uint256 level, uint256 index) external view returns (uint256);

    function getTokenLevel(uint256 tokenNumber) external view returns (uint256);
}
