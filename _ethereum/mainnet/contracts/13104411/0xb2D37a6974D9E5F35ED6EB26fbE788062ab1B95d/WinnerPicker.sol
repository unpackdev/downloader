// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./VRFConsumerBase.sol";

contract Winner is VRFConsumerBase, Ownable {
    bytes32 internal keyHash;
    uint256 internal fee;
    
    uint256[] public randomResults;
    uint256[][] public expandedResults;

    string[] public ipfsGiveawayData;

    event Winners(uint256 randomResult, uint256[] expandedResult);
    
    constructor(
        address _vrfCoordinator,
        address _linkToken,
        bytes32 _keyHash,
        uint256 _fee,
        string memory _ipfsGiveawayData
    ) VRFConsumerBase(
        _vrfCoordinator,
        _linkToken
    ) {
        keyHash = _keyHash;
        fee = _fee;
        ipfsGiveawayData.push(_ipfsGiveawayData);
    }

    function addGiveawayData(string memory _ipfsGiveawayData) external onlyOwner {
        ipfsGiveawayData.push(_ipfsGiveawayData);
    }    

    /**
     * Requests randomness
     */
    function getRandomNumber() external onlyOwner returns (bytes32 requestId) {
        require(
            LINK.balanceOf(address(this)) >= fee,
            "Not enough LINK - fill contract with faucet"
        );
        return requestRandomness(keyHash, fee);
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        randomResults.push(randomness);
    }

    function expand(uint256 numWinners, uint256 drawId, uint256 snapshotEntries) external onlyOwner {
      uint256[] memory expandedValues = new uint256[](numWinners);
      for (uint256 i = 0; i < numWinners; i++) {
        expandedValues[i] = (uint256(keccak256(abi.encode(randomResults[drawId], i))) % snapshotEntries) + 1;
      }
      expandedResults.push(expandedValues);
      emit Winners(randomResults[drawId], expandedValues);
    }


    function withdrawLink() external onlyOwner {
      LINK.transfer(owner(), LINK.balanceOf(address(this)));
    }
}
