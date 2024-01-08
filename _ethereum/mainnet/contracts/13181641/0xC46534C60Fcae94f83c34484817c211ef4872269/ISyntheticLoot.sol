// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.4;

/*

    Synthetic Loot
    
    This contract creates a "virtual NFT" of Loot based
    on a given wallet address. 
    
    Because the wallet address is used as the deterministic 
    seed, there can only be one Loot bag per wallet. 
    
    Because it's not a real NFT, there is no 
    minting, transferability, etc.
    
    Creators building on top of Loot can choose to recognize 
    Synthetic Loot as a way to allow a wider range of 
    adventurers to participate in the ecosystem, while
    still being able to differentiate between 
    "original" Loot and Synthetic Loot.
    
    Anyone with an Ethereum wallet has Synthetic Loot.
    
    -----
    
    Also optionally returns data in LootComponents format:
    
    Call weaponComponents(), chestComponents(), etc. to get 
    an array of attributes that correspond to the item. 
    
    The return format is:
    
    uint256[5] =>
        [0] = Item ID
        [1] = Suffix ID (0 for none)
        [2] = Name Prefix ID (0 for none)
        [3] = Name Suffix ID (0 for none)
        [4] = Augmentation (0 = false, 1 = true)
    
    See the item and attribute tables below for corresponding IDs.
    
    The original LootComponents contract is at address:
    0x3eb43b1545a360d1D065CB7539339363dFD445F3

*/

interface ISyntheticLoot {
    
    function tokenURI(address walletAddress) external view returns (string memory);
    
    function getWeapon(address walletAddress) external view returns (string memory);
    function getChest(address walletAddress) external view returns (string memory);
    function getHead(address walletAddress) external view returns (string memory);
    function getWaist(address walletAddress) external view returns (string memory);
    function getFoot(address walletAddress) external view returns (string memory);
    function getHand(address walletAddress) external view returns (string memory);
    function getNeck(address walletAddress) external view returns (string memory);
    function getRing(address walletAddress) external view returns (string memory);

    function weaponComponents(address walletAddress) external view returns (uint256[5] memory);
    function chestComponents(address walletAddress) external view returns (uint256[5] memory);
    function headComponents(address walletAddress) external view returns (uint256[5] memory);
    function waistComponents(address walletAddress) external view returns (uint256[5] memory);
    function footComponents(address walletAddress) external view returns (uint256[5] memory);
    function handComponents(address walletAddress) external view returns (uint256[5] memory);
    function neckComponents(address walletAddress) external view returns (uint256[5] memory);
    function ringComponents(address walletAddress) external view returns (uint256[5] memory);
}
