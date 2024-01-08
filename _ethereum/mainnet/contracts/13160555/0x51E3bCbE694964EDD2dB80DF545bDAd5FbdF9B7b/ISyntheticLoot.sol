// SPDX-License-Identifier: Unlicense
pragma solidity 0.7.6;

interface ISyntheticLoot {

    function weaponComponents(address walletAddress) external view returns (uint256[5] memory);

    function chestComponents(address walletAddress) external view returns (uint256[5] memory);

    function headComponents(address walletAddress) external view returns (uint256[5] memory);

    function waistComponents(address walletAddress) external view returns (uint256[5] memory);

    function footComponents(address walletAddress) external view returns (uint256[5] memory);

    function handComponents(address walletAddress) external view returns (uint256[5] memory);

    function neckComponents(address walletAddress) external view returns (uint256[5] memory);

    function ringComponents(address walletAddress) external view returns (uint256[5] memory);

    function getWeapon(address walletAddress) external view returns (string memory);

    function getChest(address walletAddress) external view returns (string memory);

    function getHead(address walletAddress) external view returns (string memory);

    function getWaist(address walletAddress) external view returns (string memory);

    function getFoot(address walletAddress) external view returns (string memory);

    function getHand(address walletAddress) external view returns (string memory);

    function getNeck(address walletAddress) external view returns (string memory);

    function getRing(address walletAddress) external view returns (string memory);

    function tokenURI(address walletAddress) external view returns (string memory);

}
