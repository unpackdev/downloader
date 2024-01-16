//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./Withdrawable.sol";
import "./IAddressResolver.sol";
import "./IIngameItems.sol";
import "./IPirateStaking.sol";

contract PirateUpgrading is Ownable, Withdrawable {

    IAddressResolver public addressResolver;
    IERC721 public piratesContract;
    IIngameItems public ingameItemsContract;
    IPirateStaking public pirateStakingContract;

    uint8 public gemCountForCaptain;

    mapping(uint256 => bool) public captainStatus;

    constructor(){
        gemCountForCaptain = 3;
    }

    function setAddressResolver(address address_) external onlyOwner {
        addressResolver = IAddressResolver(address_);
    }

    function importContracts() external onlyOwner {
        piratesContract = IERC721(addressResolver.getAddress("Pirates"));
        ingameItemsContract = IIngameItems(addressResolver.getAddress("IngameItems"));
        pirateStakingContract = IPirateStaking(addressResolver.getAddress("PiratesStaking"));
    }

    function setGemCountForCaptain(uint8 gemCount) external onlyOwner {
        gemCountForCaptain = gemCount;
    }

    // Uprade pirates

    // @notice player can upgrade his own pirates to captain with gems
    // @dev O(N) dependent of gemCountForCaptain
    function upgradePirateToCaptain(uint256 nftId) external {      
        require(piratesContract.ownerOf(nftId) == msg.sender, "You don't own this pirate NFT");
        require(!captainStatus[nftId], "Pirate already upgraded to captain");
        require(ingameItemsContract.viewGemCountForPlayer(msg.sender) >= gemCountForCaptain, "Not enough gems");
        for (uint8 i; i < gemCountForCaptain; i++) {
            ingameItemsContract.removeGemFromPlayer(msg.sender);
        }
        captainStatus[nftId] = true;
    }

    // @notice player can upgrade his own pirates to captain with gems
    // @dev O(N) dependent of gemCountForCaptain
    // @dev O(N) dependent of number of pirates staked, unfortunately
    function upgradeStakedPirateToCaptain(uint256 nftId) external {
        require(!captainStatus[nftId], "Pirate already upgraded to captain");
        require(ingameItemsContract.viewGemCountForPlayer(msg.sender) >= gemCountForCaptain, "Not enough gems");
        uint256[] memory stakedPirates = pirateStakingContract.getStakedPiratesForPlayer(msg.sender);
        bool isStakedBySender = false;
        for (uint256 i; i < stakedPirates.length; i++){
            if (i == nftId) {
                isStakedBySender = true;
                break;
            }
        }
        assert(isStakedBySender);
        for (uint8 i; i < gemCountForCaptain; i++) {
            ingameItemsContract.removeGemFromPlayer(msg.sender);
        }
        captainStatus[nftId] = true;
    }

    function isCaptain(uint256 nftId) public view returns (bool) {
        return captainStatus[nftId];
    }
}