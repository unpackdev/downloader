// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./IRoshambo.sol";

string constant ROOT = "<svg version='1.1' viewBox='0 0 1200 1200' xmlns='http://www.w3.org/2000/svg'>";
string constant TRANSFORM = "<g opacity='0' transform='scale (-1, 1)' transform-origin='center'>";
string constant REVEAL = "</path><animate attributeName='opacity' from='0' to='1' begin='6s' dur='3s' fill='freeze'/></g>";

/// @title Interface for Renderer contract
interface IRenderer {
    function generateImage(
        uint256 _tokenId,
        uint256 _pot,
        address _player1,
        Choice _choice1,
        address _player2,
        Choice _choice2
    ) external pure returns (string memory);

    function generatePalette(
        uint256 _tokenId,
        uint256 _pot,
        address _player1,
        Choice _choice1,
        address _player2,
        Choice _choice2
    ) external pure returns (string memory, string memory, string memory);

    function getChoice(Choice _choice) external pure returns (string memory);

    function getStage(Stage _stage) external pure returns (string memory);
}
