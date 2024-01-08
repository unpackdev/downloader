// SPDX-License-Identifier: MIT

/// @title: Metavaders - Invasion
/// @author: PxGnome
/// @notice: Used to interact with metavaders NFT contract
/// @dev: This is Version 1.0
//
// ███╗   ███╗███████╗████████╗ █████╗ ██╗   ██╗ █████╗ ██████╗ ███████╗██████╗ ███████╗
// ████╗ ████║██╔════╝╚══██╔══╝██╔══██╗██║   ██║██╔══██╗██╔══██╗██╔════╝██╔══██╗██╔════╝
// ██╔████╔██║█████╗     ██║   ███████║██║   ██║███████║██║  ██║█████╗  ██████╔╝███████╗
// ██║╚██╔╝██║██╔══╝     ██║   ██╔══██║╚██╗ ██╔╝██╔══██║██║  ██║██╔══╝  ██╔══██╗╚════██║
// ██║ ╚═╝ ██║███████╗   ██║   ██║  ██║ ╚████╔╝ ██║  ██║██████╔╝███████╗██║  ██║███████║
// ╚═╝     ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝  ╚═══╝  ╚═╝  ╚═╝╚═════╝ ╚══════╝╚═╝  ╚═╝╚══════╝
//
pragma solidity ^0.8.0;

import "./Strings.sol";
import "./Ownable.sol";

// Abstract Contract Used for Inheriting
abstract contract IMetavader {
    function changeMode(uint256 tokenId, string memory mode) public virtual;
    function ownerOf(uint256 tokenId) public view virtual returns (address);
    function getBaseURI() public view virtual returns (string memory);
    function tokenURI(uint256 tokenId) public view virtual returns (string memory);
}

// Abstract Contract Used for Inheriting
abstract contract mvCustomIERC721 {
    function balanceOf(address owner) public view virtual returns (uint256);
    function ownerOf(uint256 tokenId) public view virtual returns (address);
    function approve(address to, uint256 tokenId) public virtual;
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual;
}

contract Invasion is 
    Ownable
{   
    using Strings for uint256;

    address public vaultAddress;
    address public invadeAddress;
    address public metavadersAddress;
    bool public paused = true;

    IMetavader MetavaderContract;
    mvCustomIERC721 InvasionContract;

    // -- CONSTRUCTOR FUNCTIONS -- //
    // 10101 Metavaders in total
    constructor(address _metavadersAddress, address _invadeAddress) {
        metavadersAddress = _metavadersAddress;
        invadeAddress = _invadeAddress;
        vaultAddress = owner();
        MetavaderContract = IMetavader(_metavadersAddress);
        InvasionContract = mvCustomIERC721(_invadeAddress);
    }

    // // -- UTILITY FUNCTIONS -- //
    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    // -- SMART CONTRACT OWNER ONLY FUNCTIONS -- //
    // Change Vault Address For Future Use
    function updateVaultAddress(address _address) public onlyOwner {
        vaultAddress = _address;
    }
    // Update Invade Address Incase There Is an Issue
    function updateInvadeAddress(address _address) public onlyOwner {
        invadeAddress = _address;
    }
    // Update Invade Address Incase There Is an Issue
    function updateMetavadersAddress(address _address) public onlyOwner {
        metavadersAddress = _address;
    }

    // Withdraw to owner addresss
    function withdrawAll() public payable onlyOwner returns (uint256) {
        uint256 balance = address(this).balance;
        require(payable(owner()).send(balance)); 
        return balance;
    }

    // Pause sale/mint in case of special reason
    function pause(bool val) public onlyOwner {
        paused = val;
    }

    // -- INVADER RELATED FUNCTIONS -- //
    // In this case relates to Animetas
    function getInvadeAddress() public view returns (address) {
        return invadeAddress;
    }
    function getInvaderBalance() public view returns (uint256) {
        return InvasionContract.balanceOf(_msgSender());
    }
    function getInvaderOwnerOf(uint256 tokenId) public view returns (address) {
        return InvasionContract.ownerOf(tokenId);
    }

    // -- CUSTOM ADD ONS  --//
    // // // Change back the Metavaders' mode to normal
    function changeModeMetavaders_Normal(uint256 tokenId) public virtual {
        require(!paused, "Invasion is on hold");
        require(MetavaderContract.ownerOf(tokenId) == _msgSender(), "Must be the owner of the Metavader to execute");
        require(!compareStrings(MetavaderContract.tokenURI(tokenId), string(abi.encodePacked(MetavaderContract.getBaseURI(), tokenId.toString(), "C"))), "Metavader has transformed and cannot revert");
        MetavaderContract.changeMode(tokenId, ""); 
    }

    // // // Changes the Metavaders' mode when also own an Invaded NFT
    function changeModeMetavaders_Animetas(uint256 tokenId) public virtual {
        require(!paused, "Invasion is on hold");
        require(MetavaderContract.ownerOf(tokenId) == _msgSender(), "Must be the owner of the Metavader to execute");
        require(InvasionContract.balanceOf(_msgSender()) > 0,  "You needs to own Animetas NFT to activate");
        require(!compareStrings(MetavaderContract.tokenURI(tokenId), string(abi.encodePacked(MetavaderContract.getBaseURI(), tokenId.toString(), "C"))), "Metavader has transformed and cannot revert");
        MetavaderContract.changeMode(tokenId, "A"); 
    }

    // // // Permenanetly changes the Metavaders' mode if willing to give up the Invaded NFT -- NOTE: NEED APPROVAL PRIOR
    function transformMetavaders(uint256 tokenId, uint256 animetas_tokenId) public virtual {
        require(MetavaderContract.ownerOf(tokenId) == _msgSender(), "Must be the owner of the Metavader to execute");
        require(InvasionContract.ownerOf(animetas_tokenId) == _msgSender(), "Sender is not owner nor approved for Animetas Token");
        require(!compareStrings(MetavaderContract.tokenURI(tokenId), string(abi.encodePacked(MetavaderContract.getBaseURI(), tokenId.toString(), "C"))), "Metavader has transformed and cannot revert");
        InvasionContract.safeTransferFrom(_msgSender(),  vaultAddress, animetas_tokenId);
        MetavaderContract.changeMode(tokenId, "B"); 
    }

}
