// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "./IMasterVault.sol";
import "./IProposal.sol";

/// @title This proposal rebalances all Moonbeam TVL to Polygon
contract Proposal_231003_01_Rebalance_Moonbeam_Polygon is IProposal {
    function execute() external {
        IMasterVault masterVault = IMasterVault(0x66A3188a218c4fA5a151FE6cDefe7ffE59606304);
        masterVault.rebalance(1284, 137, 1000, 1);
    }
}
