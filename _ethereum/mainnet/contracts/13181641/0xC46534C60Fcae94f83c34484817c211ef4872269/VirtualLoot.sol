// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.4;

/// @title VirtualLoot
/// @author jpegmint.xyz

import "./ERC721Virtual.sol";
import "./ISyntheticLoot.sol";
import "./Ownable.sol";

/////////////////////////////////////////////////////////////////
//   _    ___      __              __   __                __   //
//  | |  / (_)____/ /___  ______ _/ /  / /   ____  ____  / /_  //
//  | | / / / ___/ __/ / / / __ `/ /  / /   / __ \/ __ \/ __/  //
//  | |/ / / /  / /_/ /_/ / /_/ / /  / /___/ /_/ / /_/ / /_    //
//  |___/_/_/   \__/\__,_/\__,_/_/  /_____/\____/\____/\__/    //
//                                                             //
//  Mintable Synthetic Loot                                    //
//  https://twitter.com/dhof/status/1433110412187287560?s=20   //
//                                                             //
/////////////////////////////////////////////////////////////////

contract VirtualLoot is ERC721Virtual, Ownable {

    ISyntheticLoot private _syntheticLoot;

    constructor (address syntheticLootAddress) ERC721Virtual("VirtualLoot", "vLOOT") {
        _syntheticLoot = ISyntheticLoot(syntheticLootAddress);
    }

    function mintLoot() external {
        _mint(msg.sender);
    }

    function burnLoot(address walletAddress) external {
        uint160 tokenId = uint160(walletAddress);
        require(_isApprovedOrOwner(_msgSender(), tokenId), "VirtualLoot: burn caller is not owner nor approved");
        _burn(tokenId);
    }
    
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return _syntheticLoot.tokenURI(ownerOf(tokenId));
    }

    function weaponComponents(address walletAddress) public view returns (uint256[5] memory) {
        return _syntheticLoot.weaponComponents(walletAddress);
    }
    
    function chestComponents(address walletAddress) public view returns (uint256[5] memory) {
        return _syntheticLoot.chestComponents(walletAddress);
    }
    
    function headComponents(address walletAddress) public view returns (uint256[5] memory) {
        return _syntheticLoot.headComponents(walletAddress);
    }
    
    function waistComponents(address walletAddress) public view returns (uint256[5] memory) {
        return _syntheticLoot.waistComponents(walletAddress);
    }

    function footComponents(address walletAddress) public view returns (uint256[5] memory) {
        return _syntheticLoot.footComponents(walletAddress);
    }
    
    function handComponents(address walletAddress) public view returns (uint256[5] memory) {
        return _syntheticLoot.handComponents(walletAddress);
    }
    
    function neckComponents(address walletAddress) public view returns (uint256[5] memory) {
        return _syntheticLoot.neckComponents(walletAddress);
    }
    
    function ringComponents(address walletAddress) public view returns (uint256[5] memory) {
        return _syntheticLoot.ringComponents(walletAddress);
    }
    
    function getWeapon(address walletAddress) public view returns (string memory) {
        return _syntheticLoot.getWeapon(walletAddress);
    }
    
    function getChest(address walletAddress) public view returns (string memory) {
        return _syntheticLoot.getChest(walletAddress);
    }
    
    function getHead(address walletAddress) public view returns (string memory) {
        return _syntheticLoot.getHead(walletAddress);
    }
    
    function getWaist(address walletAddress) public view returns (string memory) {
        return _syntheticLoot.getWaist(walletAddress);
    }

    function getFoot(address walletAddress) public view returns (string memory) {
        return _syntheticLoot.getFoot(walletAddress);
    }
    
    function getHand(address walletAddress) public view returns (string memory) {
        return _syntheticLoot.getHand(walletAddress);
    }
    
    function getNeck(address walletAddress) public view returns (string memory) {
        return _syntheticLoot.getNeck(walletAddress);
    }
    
    function getRing(address walletAddress) public view returns (string memory) {
        return _syntheticLoot.getRing(walletAddress);
    }
}
