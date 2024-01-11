//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IERC1155.sol";

interface ISevenOfFew {
    // State variables

    function emblems() external view returns (address);

    // Dates

    function startDate() external view returns (uint256);

    // Token info

    function puzzleOf(uint256 pieceId) external pure returns (uint256);

    function categoryOf(uint256 pieceId) external pure returns (uint256);

    // Game info

    function completedPuzzle(address addr, uint256 puzzleId)
        external
        view
        returns (bool);

    // Minting info

    function mintingPrice(uint256 categoryId) external pure returns (uint256);

    function categoryMaximumSupply(uint256 categoryId)
        external
        pure
        returns (uint256);

    function leftToMint(uint256 pieceId) external view returns (uint256);

    // Minting

    function goodlistMint(uint256 pieceId, uint256 amount) external payable;

    function goodlistMintBatch(
        uint256[] memory pieceIds,
        uint256[] memory amounts
    ) external payable;

    function publicMint(
        address to,
        uint256 pieceId,
        uint256 amount
    ) external payable;

    function publicMintBath(
        address to,
        uint256[] memory pieceIds,
        uint256[] memory amounts
    ) external payable;

    // Auction

    function bid(uint256 pieceId) external payable;

    function mintAuctionedPiece(uint256 pieceId) external;

    // Withdraw

    function withdrawETH() external;

    function withdrawERC20(address tokenAddress) external;
}
