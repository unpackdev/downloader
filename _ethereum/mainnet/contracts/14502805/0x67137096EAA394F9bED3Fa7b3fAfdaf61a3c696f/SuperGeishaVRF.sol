// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./LinkTokenInterface.sol";
import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";
import "./EnumerableSet.sol";
import "./Ownable.sol";

// Raffle List: https://ipfs.io/ipfs/bafkreihs4sknja56pzsb5dfmcwe6oxj5kxicmmk7n5fuv7z2ffs3f5jdga
contract SuperGeishaVRF is VRFConsumerBaseV2, Ownable {
    using EnumerableSet for EnumerableSet.UintSet;

    VRFCoordinatorV2Interface COORDINATOR;
    LinkTokenInterface LINKTOKEN;

    uint64 private s_subscriptionId;
    bytes32 private keyHash;
    uint256 private maxSize;
    uint32 private callbackGasLimit = 100000;
    uint16 private requestConfirmations = 3;

    uint256 public s_requestId;

    EnumerableSet.UintSet private randomWords;

    constructor(
        uint64 subscriptionId,
        address vrfCoordinator,
        address link,
        bytes32 keyHash_,
        uint256 maxSize_
    ) VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        LINKTOKEN = LinkTokenInterface(link);
        s_subscriptionId = subscriptionId;
        keyHash = keyHash_;
        maxSize = maxSize_;

        randomWords.add(0);
    }

    function requestRandomWords(uint32 numWords) external onlyOwner {
        s_requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
    }

    function fulfillRandomWords(
        uint256, /* requestId */
        uint256[] memory randomWords_
    ) internal override {
        for (uint256 i = 0; i < randomWords_.length; i++) {
            randomWords.add(randomWords_[i]);
        }
    }

    function randomWordAt(uint256 index) external view returns (uint256) {
        return randomWords.at(index);
    }

    function totalRandomWords() external view returns (uint256) {
        return randomWords.length();
    }

    function getWinner(uint256 tokenId) external view returns (uint256) {
        // adding 1 incase is perfectly divisible
        return (randomWords.at(tokenId) % (maxSize - 1)) + 1;
    }
}
