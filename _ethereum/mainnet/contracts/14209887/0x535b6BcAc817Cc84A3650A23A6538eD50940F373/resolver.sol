pragma solidity ^0.8.4;

import "./AavePool.sol";
import "./IAavePool.sol";
import "./IAaveGovernanceV2.sol";

contract AaveVoteResolver {
    function checker(AavePool aavePool, IAaveGovernanceV2 aaveGovernance)
        external
        view
        returns (bool canExec, bytes memory execPayload)
    {
        uint256 counts = aaveGovernance.getProposalsCount();
        for (uint256 i = 0; i <= counts; i++) {
            (
                uint256 totalVotes,
                uint256 proposalStartBlock,
                uint128 highestBid,
                uint64 endTime,
                bool support,
                bool voted,
                address highestBidder
            ) = aavePool.bids(i);
            IAaveGovernanceV2.ProposalWithoutVotes memory p = aaveGovernance.getProposalById(i);
            canExec =
                p.endBlock > block.number &&
                !p.executed &&
                !p.canceled &&
                !voted &&
                block.timestamp > endTime;
            execPayload = abi.encodeWithSelector(AavePool.vote.selector, i);
            if (canExec) break;
        }
    }
}
