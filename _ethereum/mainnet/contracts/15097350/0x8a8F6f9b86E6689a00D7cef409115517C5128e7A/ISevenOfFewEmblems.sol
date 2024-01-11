//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IERC721.sol";

interface ISevenOfFewEmblems {
    function completedGame(address addr) external view returns (bool);

    function mintPuzzleEmblem(address to, uint256 puzzleId) external;

    function mintGameWinnerEmblem(address to) external;

    // name

    function puzzleOf(uint256 tokenId) external view returns (uint256 puzzleId);

    function sevenOfFew() external view returns (address);

    function mintedPuzzleEmblem(address addr, uint256 puzzleId)
        external
        view
        returns (bool);
}
