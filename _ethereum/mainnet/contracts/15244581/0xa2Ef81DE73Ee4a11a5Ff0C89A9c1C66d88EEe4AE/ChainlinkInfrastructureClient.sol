// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./VRFConsumerBaseV2.sol";
import "./VRFCoordinatorV2Interface.sol";
import "./ChainlinkClient.sol";

// Chainlink and ChainlinkVRF config management contracts
import "./ChainlinkConfigManager.sol";
import "./ChainlinkVRFConfigManager.sol";

contract ChainlinkInfrastructureClient is
	ChainlinkClient,
	VRFConsumerBaseV2,
	ChainlinkConfigManager,
	ChainlinkVRFConfigManager
{
	constructor(ChainlinkConfig memory _chainlinkConfig, ChainlinkVRFConfig memory _chainlinkVRFConfig)
		ChainlinkConfigManager(_chainlinkConfig)
		ChainlinkVRFConfigManager(_chainlinkVRFConfig)
		VRFConsumerBaseV2(_chainlinkVRFConfig.vrfCoordinator)
	{
		setChainlinkToken(_chainlinkConfig.linkToken);
	}

	function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual override {}
}
