pragma solidity ^0.8.7;

import "./AggregatorProxy.sol";

library ChainlinkRoundIdCalc {
    uint256 constant private PHASE_OFFSET = 64;

    /// @return the next round ID
    // @dev if roundId is the latest round, return the same roundId to indicate that we can't go forward any more
    function next(AggregatorProxy proxy, uint256 roundId) internal view returns (uint80)
    {
        (uint16 phaseId, uint64 aggregatorRoundId) = parseIds(roundId);

        if (proxy.getAnswer(addPhase(phaseId, aggregatorRoundId+1)) != 0) {
            aggregatorRoundId++;
        }
        else if (phaseId < proxy.phaseId()) {
            phaseId++;
            aggregatorRoundId = 1;
        }
        return addPhase(phaseId, aggregatorRoundId);
    }

    /// @return the previous round ID 
    /// @dev if roundId is the first ever round, return the same roundId to indicate that we can't go back any further
    function prev(AggregatorProxy proxy, uint256 roundId) internal view returns (uint80)
    {
        (uint16 phaseId, uint64 aggregatorRoundId) = parseIds(roundId);

        if (aggregatorRoundId > 1) {
            aggregatorRoundId--;
        }
        else if (phaseId > 1) {
            phaseId--;
            // access to latestRound() is restricted, making this library pretty much useless
            // there isn't a good work around as far as I can tell
            aggregatorRoundId = uint64(proxy.phaseAggregators(phaseId).latestRound());
        }
        return addPhase(phaseId, aggregatorRoundId);
    }
    
    /// @dev copied from chainlink aggregator contract
    function addPhase(uint16 _phase, uint64 _originalId) internal pure returns (uint80)
    {
        return uint80(uint256(_phase) << PHASE_OFFSET | _originalId);
    }

    /// @dev copied from chainlink aggregator contract
    function parseIds(uint256 _roundId) internal pure returns (uint16, uint64)
    {
        uint16 phaseId = uint16(_roundId >> PHASE_OFFSET);
        uint64 aggregatorRoundId = uint64(_roundId);

        return (phaseId, aggregatorRoundId);
    }

/* 
    not useful for most applications
    
    code is untested
    /// @notice add `i` to `roundId`. Useful for searching for a particular timestamp
    /// @dev minimum possible phaseId is 1
    /// @dev minimum possible aggregatorRoundId is 1
    /// @dev if desired move amount is gt the current max ID, return the current max ID
    /// @dev if desired move amount is lt the minimum possible ID, return the minimum possible ID
    function move(AggregatorProxy proxy, uint256 roundId, int i) public view returns (uint80, int) {
        (uint16 phaseId, uint64 aggregatorRoundId) = parseIds(roundId);
        int moved = 0;
        if (i < 0) {
            while (i < 0) {
                if (-1*i < aggregatorRoundId) {
                    moved += i;
                    aggregatorRoundId += i;
                    i -= i;
                }
                else if (phaseId <= 1) {
                    moved -= aggregatorRoundId - 1;
                    aggregatorRoundId = 1;
                    i = 0;
                }
                else {
                    phaseId -= 1;
                    moved -= aggregatorRoundId;
                    i += aggregatorRoundId;
                    aggregatorRoundId = uint64(proxy.phaseAggregators(phaseId).latestRound());
                }
            }
        }
        else if (i > 0) {
            while (i > 0) {
                uint32 latestAggregatorRoundId = proxy.phaseAggregators(phaseId).latestRound();
                if (aggregatorRoundId + i <= latestAggregatorRoundId) {
                    moved += i;
                    aggregatorRoundId += i;
                    i -= i;
                }
                else if (phaseId >= proxy.phaseId()) {
                    moved += latestAggregatorRoundId - aggregatorRoundId;
                    aggregatorRoundId = latestAggregatorRoundId;
                    i = 0;
                } else {
                    phaseId += 1;
                    moved += latestAggregatorRoundId - aggregatorRoundId + 1;
                    i -= latestAggregatorRoundId - aggregatorRoundId + 1;
                    aggregatorRoundId = 1;
                }
            }
        }
        return addPhase(phaseId, aggregatorRoundId);
    }
    */
}