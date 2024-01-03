// SPDX-License-Identifier: MIT
pragma solidity >=0.6.6;

import "./VRFConsumerBase.sol";

contract RandomNumberConsumer is VRFConsumerBase {
    bytes32 internal keyHash;
    uint256 public fee;
    address public VRFCoordinator;

    // The address to which withdrawn link are given
    address public multiSigSafe;
    // The address that can request new random numbers
    address public randomizedCounter;

    uint256 public randomResult;

    constructor(
        address VRFCoordinator_,
        bytes32 keyhash_,
        address LINK,
        address multiSigSafe_,
        address randomizedCounter_,
        uint256 fee_
    )
        public
        VRFConsumerBase(
            VRFCoordinator_, // VRF Coordinator
            LINK // LINK Token
        )
    {
        VRFCoordinator = VRFCoordinator_;
        keyHash = keyhash_;
        fee = fee_;
        multiSigSafe = multiSigSafe_;
        randomizedCounter = randomizedCounter_;
    }

    function setFee(uint256 fee_) external {
        require(
            msg.sender == randomizedCounter,
            "Only counter can call this function"
        );
        fee = fee_;
    }

    /**
     * Requests randomness from a user-provided seed
     */
    function getRandomNumber(uint256 userProvidedSeed)
        public
        returns (bytes32 requestId)
    {
        require(
            msg.sender == randomizedCounter,
            "Only counter can call this function"
        );
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK");
        return requestRandomness(keyHash, fee, userProvidedSeed);
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        randomResult = randomness;
    }

    function withdrawLink() external {
        require(
            msg.sender == multiSigSafe,
            "Only multi sig safe can withdraw link"
        );
        require(
            LINK.transfer(msg.sender, LINK.balanceOf(address(this))),
            "Unable to transfer"
        );
    }
}
