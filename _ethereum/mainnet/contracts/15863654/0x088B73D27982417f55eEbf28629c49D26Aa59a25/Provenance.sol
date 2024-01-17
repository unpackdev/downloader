// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./LinkTokenInterface.sol";
import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";

import "./Ownable.sol";

import "./IProvenance.sol";

contract Provenance is IProvenance, VRFConsumerBaseV2, Ownable {
    uint256 private randomProvenance;
    bool public generated; 

    VRFCoordinatorV2Interface VRFCoordinator;
    bytes32 private immutable gasLaneKeyHash;
    uint64 public immutable linkSubscriptionId;
    uint32 private immutable callbackGasLimit;
    uint16 private immutable requestConfirmations;
    uint256 public randomRequestId;

    constructor() Ownable() VRFConsumerBaseV2(0x271682DEB8C4E0901D1a1550aD2e64D568E69909) {
        VRFCoordinator = VRFCoordinatorV2Interface(
            0x271682DEB8C4E0901D1a1550aD2e64D568E69909
        );
        linkSubscriptionId = 483;
        gasLaneKeyHash = 0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef;
        callbackGasLimit = 500000;
        requestConfirmations = 3;
    }

    function getRandomProvenance() public view returns (uint256) {
        if (!generated) revert ProvenanceNotGenerated();
        return randomProvenance;
    } 

    function generateRandomProvenance() public onlyOwner {
        if (generated) revert ProvenanceAlreadyGenerated();
        if (randomRequestId > 0) revert ProvenanceAlreadyRequested();
        
        randomRequestId = VRFCoordinator.requestRandomWords(
            gasLaneKeyHash,
            linkSubscriptionId,
            requestConfirmations,
            callbackGasLimit,
            1
        );
    }

    function fulfillRandomWords(uint256, uint256[] memory randomWords)
        internal
        override
    {
        randomProvenance = randomWords[0];
        generated = true;
    }
}
