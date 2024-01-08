// SPDX-License-Identifier: MIT
/*
    _____  __    __  ______   ______   ________ 
   /     |/  |  /  |/      | /      \ /        |
   $$$$$ |$$ |  $$ |$$$$$$/ /$$$$$$  |$$$$$$$$/ 
      $$ |$$ |  $$ |  $$ |  $$ |  $$/ $$ |__    
 __   $$ |$$ |  $$ |  $$ |  $$ |      $$    |   
/  |  $$ |$$ |  $$ |  $$ |  $$ |   __ $$$$$/    
$$ \__$$ |$$ \__$$ | _$$ |_ $$ \__/  |$$ |_____ 
$$    $$/ $$    $$/ / $$   |$$    $$/ $$       |
 $$$$$$/   $$$$$$/  $$$$$$/  $$$$$$/  $$$$$$$$/ 
 */
//This token is purely for use within the vApez ecosystem
//It has no economic value whatsoever

pragma solidity ^0.8.0;

import "./ERC20Burnable.sol";
import "./Ownable.sol";
import "./ERC721.sol";

contract Juice is ERC20Burnable, Ownable {
    uint256 public START_BLOCK;
    uint256 public BASE_RATE = 1 ether;
    address public vapezAddress;

    //mapping of address to rewards

    //Mapping of token to timestamp
    mapping(uint256 => uint256) internal lastClaimed;

    //Event for claiming juice
    event JuiceClaimed(address indexed user, uint256 reward);

    constructor(address _vapezAddress) ERC20("Juice", "JUICE") {
        setVapezAddress(_vapezAddress);
        START_BLOCK = block.timestamp;
    }

    function setVapezAddress(address _vapezAddress) public onlyOwner {
        vapezAddress = _vapezAddress;
    }

    function claimReward(uint256 _tokenId) public returns (uint256) {
        require(
            IERC721(vapezAddress).ownerOf(_tokenId) == msg.sender,
            "Caller does not own the vApe"
        );

        //set last claim to start block if hasnt been claimed before
        if (lastClaimed[_tokenId] == uint256(0)) {
            lastClaimed[_tokenId] = START_BLOCK;
        }

        //compute JUICE to be claimed
        uint256 unclaimedJuice = computeRewards(_tokenId);
        lastClaimed[_tokenId] = block.timestamp;
        _mint(msg.sender, unclaimedJuice);
        emit JuiceClaimed(msg.sender, unclaimedJuice);

        return unclaimedJuice;
    }

    function claimRewards(uint256[] calldata _tokenIds)
        public
        returns (uint256)
    {
        uint256 totalUnclaimedJuice = 0;

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 _tokenId = _tokenIds[i];

            require(
                IERC721(vapezAddress).ownerOf(_tokenId) == msg.sender,
                "Caller does not own the vApe"
            );
            if (lastClaimed[_tokenId] == uint256(0)) {
                lastClaimed[_tokenId] = START_BLOCK;
            }
            uint256 unclaimedJuice = computeRewards(_tokenId);
            totalUnclaimedJuice = totalUnclaimedJuice + unclaimedJuice;
            lastClaimed[_tokenId] = block.timestamp;
        }
        _mint(msg.sender, totalUnclaimedJuice);
        emit JuiceClaimed(msg.sender, totalUnclaimedJuice);

        return totalUnclaimedJuice;
    }

    //call this method to view how much JUICE you can get on a vape
    function computeRewards(uint256 _tokenId) public view returns (uint256) {
        uint256 timeToUse;
        timeToUse = lastClaimed[_tokenId];
        if (lastClaimed[_tokenId] == uint256(0)) {
            timeToUse = START_BLOCK;
        }
        uint256 secondsElapsed = block.timestamp - timeToUse;
        uint256 accumulatedReward = (secondsElapsed * BASE_RATE) / 1 days;

        return accumulatedReward;
    }

    //call this method to compute the rewards for multiple vapez
    function computeMultipleRewards(uint256[] calldata _tokenIds)
        public
        view
        returns (uint256)
    {
        uint256 totalRewards = 0;
        for (uint256 index = 0; index < _tokenIds.length; index++) {
            totalRewards = totalRewards + computeRewards(_tokenIds[index]);
        }
        return totalRewards;
    }
}
