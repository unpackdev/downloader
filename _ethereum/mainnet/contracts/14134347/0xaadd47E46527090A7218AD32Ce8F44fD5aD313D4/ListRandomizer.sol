// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./Counters.sol";

import "./VRFConsumerBase.sol";

/*
* @title Contract for Pixelvault list randomizations using Chainlink VRF 
*
* @author Niftydude
*/
contract ListRandomizer is VRFConsumerBase, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private counter; 

    bytes32 internal keyHash;
    uint256 internal fee;

    mapping(uint256 => Randomization) public randomizations;

    struct Randomization {
        uint256 listLength;
        string description;
        uint256 randomNumber;
        bool isFulfilled;
        string entryListIpfsHash;
    }

    constructor(
        address _vrfCoordinator,
        address _linkToken,
        bytes32 _keyHash,
        uint256 _fee
    ) VRFConsumerBase(_vrfCoordinator, _linkToken) {
        keyHash = _keyHash;
        fee = _fee;
    }   

    /**
    * @notice initiate a new randomization
    * 
    * @param _listLength the number of entries in the list
    * @param _entryListIpfsHash ipfs hash pointing to the list of entries
    * 
    */
    function startRandomization(
        uint256 _listLength, 
        string memory _entryListIpfsHash,
        string memory _description
    ) external onlyOwner returns (bytes32 requestId) {
        require(counter.current() == 0 || randomizations[counter.current()-1].isFulfilled, "Previous randomization not fulfilled");    
        require(
            LINK.balanceOf(address(this)) >= fee,
            "Not enough LINK"
        );

        Randomization storage d = randomizations[counter.current()];
        d.listLength = _listLength;
        d.entryListIpfsHash = _entryListIpfsHash;
        d.description = _description;

        counter.increment();

        return requestRandomness(keyHash, fee);
    }   

    /**
    * @notice return randomized list for a given randomization
    * 
    * @param _id the randomization id to return the list for
    */
    function getRandomList(uint256 _id) external view returns (uint256[] memory) {         
        require(randomizations[_id].isFulfilled, "Randomization not fulfilled yet");            

        uint256[] memory arr = new uint256[](randomizations[_id].listLength);

        for (uint256 i = 0; i < randomizations[_id].listLength; i++) {
            uint256 j = (uint256(keccak256(abi.encode(randomizations[_id].randomNumber, i))) % (i + 1));

            arr[i] = arr[j];
            arr[j] = i+1;
        }
        
        return arr;
    }    

    function withdrawLink() external onlyOwner {
        LINK.transfer(owner(), LINK.balanceOf(address(this)));
    }                

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32, uint256 randomness) internal override {
        randomizations[counter.current()-1].randomNumber = randomness;
        randomizations[counter.current()-1].isFulfilled = true;
    }
   
}
