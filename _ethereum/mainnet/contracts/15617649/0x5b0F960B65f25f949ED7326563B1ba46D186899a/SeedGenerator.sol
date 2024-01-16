// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./Ownable.sol";
import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";
import "./IPrim8.sol";

contract SeedGenerator is Ownable, VRFConsumerBaseV2 {
    // Chainklink VRF V2
    VRFCoordinatorV2Interface immutable COORDINATOR;
    uint32 immutable callbackGasLimit;
    uint16 immutable requestConfirmations;
    bytes32 immutable keyHash;
    uint64 immutable subscriptionId;

    bool public randomseedRequested;
    address public nftContract;
    uint16 constant numWords = 1;

    event RandomnessRequest(uint256 requestId);
    event FulfillRandomWords(uint256 requestId, uint256 genSeed);

    constructor(
        address coordinator,
        bytes32 _keyhHash,
        uint64 _subscriptionId,
        uint32 _callbackGasLimit,
        uint16 _requestConfirmations
    ) VRFConsumerBaseV2(coordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(coordinator);
        keyHash = _keyhHash;
        subscriptionId = _subscriptionId;
        callbackGasLimit = _callbackGasLimit;
        requestConfirmations = _requestConfirmations;
        randomseedRequested = false;
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        uint256 randomness = randomWords[0];
        IPrim8(nftContract).setSeed(randomness);
        emit FulfillRandomWords(requestId, randomness);
    }

    function reveal() external onlyOwner {
        require(!randomseedRequested, "Chainlink VRF already requested");
        uint256 requestId = COORDINATOR.requestRandomWords(
            keyHash,
            subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        randomseedRequested = true;
        emit RandomnessRequest(requestId);
    }

    function setNFTContract(address _nftContract) external onlyOwner {
        require(_nftContract != address(0), "can not be null");
        // check signature function set seed
        nftContract = _nftContract;
    }
}
