// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface LootInterface {

    function getWeapon(uint256 tokenId) external view returns (string memory);
    
    function getChest(uint256 tokenId) external view returns (string memory);
    
    function getHead(uint256 tokenId) external view returns (string memory);
    
    function getWaist(uint256 tokenId) external view returns (string memory);

    function getFoot(uint256 tokenId) external view returns (string memory);
    
    function getHand(uint256 tokenId) external view returns (string memory);
    
    function getNeck(uint256 tokenId) external view returns (string memory);
    
    function getRing(uint256 tokenId) external view returns (string memory);
    
    function balanceOf(address _owner) external view returns (uint256);

    function ownerOf(uint256 _tokenId) external view returns (address);

}