// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./Ownable.sol";
import "./VRFConsumerBase.sol";

contract RandomCollectorSelector is Ownable, VRFConsumerBase
{
    bytes32 internal keyHash;
    uint256 internal fee;
    uint256[] public randomResults;
    uint256[][] public expandedResults;
    string[] public ipfsGiveawayData;
    address public _linkToken = 0x514910771AF9Ca656af840dff83E8264EcF986CA;
    address public _vrfCoordinator = 0xf0d54349aDdcf704F77AE15b96510dEA15cb7952;
    bytes32 _keyHash = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;
    uint256 _fee = 2000000000000000000;
    event Winners(uint256 randomResult, uint256[] expandedResult);
    
    /** Constructor **/
    constructor() VRFConsumerBase( _vrfCoordinator, _linkToken) 
    {
        keyHash = _keyHash;
        fee = _fee;
    }

    function addGiveawayData(string memory ipfsString) external onlyOwner { ipfsGiveawayData.push(ipfsString); }    

    /** Requests Randomness **/
    function getRandomNumber() external onlyOwner returns (bytes32 requestId) 
    {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK");
        return requestRandomness(keyHash, fee);
    }

    /** Callback function used by VRF Coordinator **/
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override { randomResults.push(randomness); }

    /** Generates Winners Utilizing ChainLink VRF **/
    function generateWinners(uint256 numWinners, uint256 drawId, uint256 snapshotEntries) external onlyOwner 
    {
      uint256[] memory expandedValues = new uint256[](numWinners);
      for (uint256 i = 0; i < numWinners; i++) 
      {
        expandedValues[i] = (uint256(keccak256(abi.encode(randomResults[drawId], i))) % snapshotEntries) + 1;
      }
      expandedResults.push(expandedValues);
      emit Winners(randomResults[drawId], expandedValues);
    }

    function withdrawLink() external onlyOwner { LINK.transfer(owner(), LINK.balanceOf(address(this))); }
}