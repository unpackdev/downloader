// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "./IMasterVault.sol";
import "./IProposal.sol";

/// @title This proposal sets new scores for all networks and rebalances 5% of total TVL from Ethereum to Polygon
contract Proposal_230906_01_Scoring_Update is IProposal
{
	function execute() external
	{
		IMasterVault masterVault = IMasterVault(0x66A3188a218c4fA5a151FE6cDefe7ffE59606304);

		// Set new score for Arbitrum network.
		uint256[] memory chainIds = new uint256[](4);
		uint256[] memory scores = new uint256[](4);
		chainIds[0] = 1;
		scores[0] = 300;
		chainIds[1] = 137;
		scores[1] = 300;
		chainIds[2] = 1284;
		scores[2] = 250;
		chainIds[3] = 42161;
		scores[3] = 150;

		masterVault.updateScores(chainIds, scores);

		// Current share of Ethereum is 35%, 5%/35%=14.3%
		masterVault.rebalance(1, 137, 143, 1);
	}
}