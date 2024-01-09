// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./VRFConsumerBase.sol";

contract RandomNumberConsumer is VRFConsumerBase {
    bytes32 internal keyHash;
    uint256 internal fee;

    mapping(bytes32 => address) private requestIdToAddress;

    /**
     * Constructor inherits VRFConsumerBase
     */
    constructor(
        address _vrfCoordinator,
        address _LINKToken,
        bytes32 _keyHash,
        uint256 _fee
    )
        VRFConsumerBase(
            _vrfCoordinator, // VRF Coordinator
            _LINKToken // LINK Token
        )
    {
        keyHash = _keyHash;
        fee = _fee;
    }

    /**
     * Requests randomness
     */
    function getRandomNumber() public returns (bytes32) {
        require(
            LINK.balanceOf(address(this)) >= fee,
            "Not enough LINK - fill contract with faucet"
        );

        bytes32 requestId = requestRandomness(keyHash, fee);

        requestIdToAddress[requestId] = msg.sender;

        return requestId;
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        virtual
        override
    {
        address requestAddress = requestIdToAddress[requestId];
        saveRandomNumber(requestAddress, randomness);
    }

    /**
     * Derives n more random numbers from that number
     */
    function expand(uint256 randomValue, uint256 n)
        public
        pure
        returns (uint256[] memory expandedValues)
    {
        expandedValues = new uint256[](n);
        expandedValues[0] = randomValue;
        for (uint256 i = 0; i < n; i++) {
            expandedValues[i] = uint256(keccak256(abi.encode(randomValue, i)));
        }
        return expandedValues;
    }

    function saveRandomNumber(address addr, uint256 randomNumber)
        internal
        virtual
    {}
}
