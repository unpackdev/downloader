// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Strings.sol";
import "./Ownable.sol";
import "./VRFConsumerBase.sol";

contract Nezha is Ownable, VRFConsumerBase {
    event RandomseedRequested(uint256 timestamp);
    event RandomseedFulfilmentSuccess(
        uint256 timestamp,
        bytes32 requestId,
        uint256 seed
    );
    event RandomseedFulfilmentFail(uint256 timestamp, bytes32 requestId);

    bytes32 keyHash;

    mapping(string => address[]) public raffleList;
    mapping(string => string) public raffleHash;
    mapping(bytes32 => string) public requestMapping;
    string[] public raffleNames;
    mapping(string => uint256) public raffleAmount;
    mapping(string => uint256) public randomSeedMapping;
    mapping(string => bool) public randomSeedRequested;

    constructor(
        address _coordinator,
        address _linkToken,
        bytes32 _keyHash
    ) VRFConsumerBase(_coordinator, _linkToken) {
        keyHash = _keyHash;
    }

    function createRaffle(
        string memory name,
        string memory _hash,
        uint256 amount
    ) public onlyOwner {
        require(raffleAmount[name] == 0, "Raffle already exists");
        raffleList[name] = new address[](0);
        raffleAmount[name] = amount;
        raffleHash[name] = _hash;
        raffleNames.push(name);
    }

    function raffle(string memory name)
        public
        view
        returns (uint256[] memory)
    {
        uint256 listSize = raffleAmount[name];

        uint256[] memory metadata = new uint256[](listSize);
        uint256 seed = randomSeedMapping[name];
        if (seed ==0) {
            return metadata;
        }

        for (uint256 i = 0; i < listSize; i += 1) {
            metadata[i] = i;
        }

        for (uint256 i = 0; i < listSize; i += 1) {
            uint256 j = (uint256(keccak256(abi.encode(seed, i))) % (listSize));

            (metadata[i], metadata[j]) = (metadata[j], metadata[i]);
        }

        return metadata;
    }

    function requestChainlinkVRF(string memory name) external onlyOwner {
        require(!randomSeedRequested[name], "Chainlink VRF already requested");
        require(
            LINK.balanceOf(address(this)) >= 2000000000000000000,
            "Insufficient LINK"
        );
        bytes32 requestId = requestRandomness(keyHash, 2000000000000000000);
        requestMapping[requestId] = name;
        randomSeedRequested[name] = true;
        emit RandomseedRequested(block.timestamp);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomNumber)
        internal
        override
    {
        string memory raffleName = requestMapping[requestId];
        randomSeedMapping[raffleName] = randomNumber;
        emit RandomseedFulfilmentSuccess(
            block.timestamp,
            requestId,
            randomNumber
        );
    }
}
