// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./VRFConsumerBase.sol";

contract GrayRaffle is VRFConsumerBase, Ownable {
    bytes32 internal constant keyHash = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;
    uint256 internal constant fee = 2 ether;

    address public keeper = 0xa8F0d37A4DF4c2F675a10eae7292F19c46a2182b;
    
    uint256[] public randomResults; // drawId => VRF number
    // stores the random number position of the winner's address
    uint256[][] public expandedResults; // drawId => randomNumber[]  

    event Winners(uint256 randomResult, uint256[] expandedResult);
    
    constructor(
        address _vrfCoordinator,
        address _linkToken
    ) VRFConsumerBase(
        _vrfCoordinator,
        _linkToken
    ) {}

    /* ========== Owner Functions ========== */

    function getRandomNumber() external onlyOwnerOrKeeper returns (bytes32 requestId) {
        require(
            LINK.balanceOf(address(this)) >= fee,
            "Not enough LINK"
        );
        return requestRandomness(keyHash, fee);
    }

    function withdrawLink() external onlyOwner {
        LINK.transfer(owner(), LINK.balanceOf(address(this)));
    }

    function setKeeper(address newKeeper) external onlyOwnerOrKeeper {
        keeper = newKeeper;
    }

    /* ========== Chain Link Functions ========== */

    function fulfillRandomness(bytes32, uint256 randomness)
        internal
        override
    {
        randomResults.push(randomness);
    }

    function expand(uint256 numWinners, uint256 drawId, uint256 snapshotEntries) external onlyOwnerOrKeeper {
        uint256[] memory expandedValues = new uint256[](numWinners);
        for (uint256 i = 0; i < numWinners; i++) {
            expandedValues[i] = (uint256(keccak256(abi.encode(randomResults[drawId], i))) % snapshotEntries) + 1;
        }
        expandedResults.push(expandedValues);
        emit Winners(randomResults[drawId], expandedValues);
    }

    /* ========== Modifiers ========== */

    modifier onlyOwnerOrKeeper() {
        require(owner() == msg.sender || keeper == msg.sender, "only owner or keeper");
        _;
    }
}