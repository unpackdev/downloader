// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "./IMasterVault.sol";
import "./IProposal.sol";

/// @title This proposal rebalances 11.5% of total TVL from Moonbeam to Polygon
contract Proposal_230926_02_Rebalance_Moonbeam_Polygon is IProposal {
    function execute() external {
        IMasterVault masterVault = IMasterVault(0x66A3188a218c4fA5a151FE6cDefe7ffE59606304);

        // Set new scores
        uint256[] memory chainIds = new uint256[](4);
        uint256[] memory scores = new uint256[](4);
        chainIds[0] = 1;
        scores[0] = 150;
        chainIds[1] = 137;
        scores[1] = 700;
        chainIds[2] = 1284;
        scores[2] = 150;
        chainIds[3] = 42161;
        scores[3] = 0;

        // Current moonbeam share in total TVL is 26.5% 11.5/26.5=43.3%
        masterVault.rebalance(1284, 137, 433, 1);
    }
}
