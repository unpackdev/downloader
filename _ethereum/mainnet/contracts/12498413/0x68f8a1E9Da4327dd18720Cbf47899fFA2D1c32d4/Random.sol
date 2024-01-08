// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./Ownable.sol";
import "./VRFConsumerBase.sol";

contract Random is VRFConsumerBase, Ownable {
    bytes32 internal keyHash;
    uint256 internal fee;

    address[] public contestants;
    address public winner;
    uint256 public randomResult;

    constructor(
        address vrfCoor,
        address _link,
        bytes32 _keyHash
    ) VRFConsumerBase(vrfCoor, _link) {
        keyHash = _keyHash;
        fee = 0.1 * 10**18; // 0.1 LINK (Varies by network)
    }

    /**
     * Requests randomness from a user-provided seed
     */
    function getRandomNumber(uint256 userProvidedSeed)
        public
        returns (bytes32 requestId)
    {
        require(
            LINK.balanceOf(address(this)) >= fee,
            "Not enough LINK - fill contract with faucet"
        );
        return requestRandomness(keyHash, fee, userProvidedSeed);
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 , uint256 randomness)
        internal
        override
    {
        randomResult = randomness  % contestants.length;
        winner = contestants[randomResult];
    }

    function withdrawLink() external onlyOwner {
        LINK.transfer(msg.sender, LINK.balanceOf(address(this)));
    }

    function depositLink(uint256 _value) external onlyOwner {
        LINK.transferFrom(msg.sender, address(this), _value);
    }

    function addContestants(address[] calldata _contestants)
        external
        onlyOwner
    {
        contestants = _contestants;
    }

    function getContestants() external view returns (address[] memory) {
        return contestants;
    }
}
