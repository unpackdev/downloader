// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./Counters.sol";

abstract contract Reward is Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private counter; 

    mapping(uint256 => Reward) public rewards;

    struct Reward {
        string ipfsMetadataHash;  
        string name;
        string description;
    }
    
    /**
    * @notice adds a new Reward
    * 
    * @param _ipfsMetadataHash the ipfs hash for Reward metadata
    * @param _name is the name of the Reward
    * @param _description is the description for the Reward
    */
    function addReward(         
        string memory _ipfsMetadataHash,
        string memory _name,
        string memory _description
    ) external onlyOwner {
        Reward storage c = rewards[counter.current()];
        c.ipfsMetadataHash = _ipfsMetadataHash;
        c.name = _name;                                       
        c.description = _description;
        counter.increment();
    }    

    /*
    * @notice edit an existing Reward
    * 
    * @param _ipfsMetadataHash the ipfs hash for Reward metadata
    * @param _name is the name of the Reward
    * @param _description is the description for the Reward
    * @param _rewardIndex
    */
    function editReward(      
        string memory _ipfsMetadataHash,
        string memory _name,
        string memory _description,
        uint256 _rewardIndex
    ) external onlyOwner {
        rewards[_rewardIndex].ipfsMetadataHash = _ipfsMetadataHash;  
        rewards[_rewardIndex].name = _name;                               
        rewards[_rewardIndex].description = _description;  
    }
}