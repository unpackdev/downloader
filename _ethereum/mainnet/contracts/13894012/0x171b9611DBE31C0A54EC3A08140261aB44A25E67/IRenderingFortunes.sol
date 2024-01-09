// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IRenderingFortunes {
    function getImageURI(uint256, string memory) external pure returns (string memory);
    function getFullLine(uint256) external pure returns (string memory);
    function renderText(string[3] memory) external view returns (string memory);
    function getLine1_A(uint256) external view returns (string memory);
    function getLine2_A(uint256) external view returns (string memory);
    function getLine3_A(uint256) external view returns (string memory);
    function getLine1_B(uint256) external view returns (string memory);
    function getLine2_B(uint256) external view returns (string memory);
    function getLine3_B(uint256) external view returns (string memory);
}