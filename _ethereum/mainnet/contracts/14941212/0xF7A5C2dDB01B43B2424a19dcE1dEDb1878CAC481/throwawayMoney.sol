// SPDX-License-Identifier: MIT
// Lets throw away a stupid fucking Burger.
// This contract is totally stolen.
pragma solidity ^0.8.7;

import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";
import "./Ownable.sol";

contract ThrowawayMoney is VRFConsumerBaseV2, Ownable {
	VRFCoordinatorV2Interface COORDINATOR;

	uint64 s_subscriptionId;
	address vrfCoordinator = 0x271682DEB8C4E0901D1a1550aD2e64D568E69909;
	bytes32 keyHash =
		0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef;
	uint32 callbackGasLimit = 100000;
	uint16 requestConfirmations = 3;
	uint256 public s_randomRange;
	uint256[] public s_randomWords;
	uint256 public s_requestId;
	address s_owner;

	constructor(uint64 subscriptionId) VRFConsumerBaseV2(vrfCoordinator) {
		COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
		s_owner = msg.sender;
		s_subscriptionId = subscriptionId;
	}

	event Winner(uint256 Winner);

	function requestRandomWords() external onlyOwner {
		s_requestId = COORDINATOR.requestRandomWords(
			keyHash,
			s_subscriptionId,
			requestConfirmations,
			callbackGasLimit,
			1
		);
	}

	function fulfillRandomWords(uint256, uint256[] memory randomWords)
		internal
		override
	{
		s_randomRange = (randomWords[0] % 8888) + 1;
		emit Winner(s_randomRange);
	}
}
