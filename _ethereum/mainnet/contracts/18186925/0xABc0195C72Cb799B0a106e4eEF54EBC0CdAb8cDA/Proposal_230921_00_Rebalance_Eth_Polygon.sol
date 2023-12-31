// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "./IProposal.sol";
import "./IMasterVault.sol";

/// @title This proposal rebalances 15% of total TVL from Ethereum to Polygon network
contract Proposal_230921_00_Rebalance_Eth_Polygon is IProposal {
    function execute() external {
        IMasterVault masterVault = IMasterVault(0x66A3188a218c4fA5a151FE6cDefe7ffE59606304);

        // Current ethereum share in total TVL is 30% 15/30=50
        masterVault.rebalance(1, 137, 500, 1);
    }
}
