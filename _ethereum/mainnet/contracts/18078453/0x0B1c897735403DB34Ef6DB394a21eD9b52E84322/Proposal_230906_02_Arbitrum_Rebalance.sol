// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "./IMasterVault.sol";
import "./IProposal.sol";

/// @title This proposal rebalances 13.4% of total TVL from Moonbeam to Arbitrum
contract Proposal_230906_02_Arbitrum_Rebalance is IProposal
{
	function execute() external
	{
		IMasterVault masterVault = IMasterVault(0x66A3188a218c4fA5a151FE6cDefe7ffE59606304);

		// Current moonbeam share in total TVL is 40% 13.4/40=33.5%
		masterVault.rebalance(1284, 42161, 335, 1);
	}
}