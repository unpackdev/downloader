// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;
import "./IERC721Enumerable.sol";
import "./IERC721Metadata.sol";

interface ILoot is IERC721Enumerable, IERC721Metadata {
    function getWeapon(uint256 tokenId) external view returns (string memory);

    function getChest(uint256 tokenId) external view returns (string memory);

    function getHead(uint256 tokenId) external view returns (string memory);

    function getWaist(uint256 tokenId) external view returns (string memory);

    function getFoot(uint256 tokenId) external view returns (string memory);

    function getHand(uint256 tokenId) external view returns (string memory);

    function getNeck(uint256 tokenId) external view returns (string memory);

    function getRing(uint256 tokenId) external view returns (string memory);
}
