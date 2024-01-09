//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./SafeMath.sol";
import "./VRFConsumerBase.sol";
import "./GenesisSupplySBInterface.sol";

contract GenesisReveal is VRFConsumerBase, Ownable {
    using SafeMath for uint256;

    DeployedSupply private supply;
    uint256 public constant SHIFTED_SUPPLY = 1071;
    uint256 public constant MAX_SUPPLY = 1077;
    uint256 public constant RESERVED_GODS_MAX_SUPPLY = 6;

    /**
     * Chainlink VRF
     */
    bytes32 private keyHash;
    uint256 private fee;
    bytes32 private randomizationRequestId;
    uint256 public shiftValue;

    constructor(
        address supplyAddress,
        address vrfCoordinator,
        address linkToken,
        bytes32 _keyhash,
        uint256 _fee
    ) VRFConsumerBase(vrfCoordinator, linkToken) {
        supply = DeployedSupply(supplyAddress);
        keyHash = _keyhash;
        fee = _fee;
    }

    /**
     * Returns the metadata of a token
     * @param tokenId id of the token
     * @return traits metadata of the token
     */
    function getMetadataForTokenId(uint256 tokenId)
        public
        view
        validTokenId(tokenId)
        returns (DeployedSupply.TokenTraits memory traits)
    {
        require(shiftValue > 0, "ShiftValue not initialized");
        if (tokenId < RESERVED_GODS_MAX_SUPPLY) {
            return supply.getMetadataForTokenId(tokenId);
        } else {
            // We add shift value to tokenID, modulo total supply to be [0..1070]
            // then add reserved count for index to be [6..1076]
            uint256 shiftedIndex = ((shiftValue + tokenId) % SHIFTED_SUPPLY) +
                RESERVED_GODS_MAX_SUPPLY;
            return supply.getMetadataForTokenId(shiftedIndex);
        }
    }

    /**
     * Will request a random number from Chainlink to be stored privately in the contract
     */
    function generateSeed() external onlyOwner {
        require(shiftValue == 0, "Already generated");
        require(randomizationRequestId == 0, "Randomization already started");
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK");
        randomizationRequestId = requestRandomness(keyHash, fee);
    }

    /**
     * Callback when a random number gets generated
     * @param requestId id of the request sent to Chainlink
     * @param randomNumber random number returned by Chainlink
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomNumber)
        internal
        override
    {
        require(requestId == randomizationRequestId, "Invalid requestId");
        require(shiftValue == 0, "Already generated");
        uint256 tempShift = randomNumber % SHIFTED_SUPPLY;
        // if random number is multiple of SHIFTED_SUPPLY, use 1
        if (tempShift == 0) {
            shiftValue = 1;
        } else {
            shiftValue = tempShift;
        }
    }

    /**
     *  Modifiers
     */

    /**
     * Modifier that checks for a valid tokenId
     * @param tokenId token id
     */
    modifier validTokenId(uint256 tokenId) {
        require(tokenId < MAX_SUPPLY, "Invalid tokenId");
        require(tokenId >= 0, "Invalid tokenId");
        _;
    }
}
