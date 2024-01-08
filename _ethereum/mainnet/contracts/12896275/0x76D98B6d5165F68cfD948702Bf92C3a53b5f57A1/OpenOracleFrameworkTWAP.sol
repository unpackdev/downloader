// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "./Address.sol";

interface IOpenOracleFramework {
    /**
    * @dev getHistoricalFeeds function lets the caller receive historical values for a given timestamp
    *
    * @param feedIDs the array of feedIds
    * @param timestamps the array of timestamps
    */
    function getHistoricalFeeds(uint256[] memory feedIDs, uint256[] memory timestamps) external view returns (uint256[] memory);

    /**
    * @dev getFeeds function lets anyone call the oracle to receive data (maybe pay an optional fee)
    *
    * @param feedIDs the array of feedIds
    */
    function getFeeds(uint256[] memory feedIDs) external view returns (uint256[] memory, uint256[] memory, uint256[] memory);

    /**
    * @dev getFeed function lets anyone call the oracle to receive data (maybe pay an optional fee)
    *
    * @param feedID the array of feedId
    */
    function getFeed(uint256 feedID) external view returns (uint256, uint256, uint256);

    /**
    * @dev getFeedList function returns the metadata of a feed
    *
    * @param feedIDs the array of feedId
    */
    function getFeedList(uint256[] memory feedIDs) external view returns(string[] memory, uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory);
}

contract OOFTWAP {

    // using Openzeppelin contracts for SafeMath and Address
    using Address for address;

    constructor() {
        
    }

    //---------------------------view functions ---------------------------

    function getTWAP(IOpenOracleFramework OOFContract, uint256[] memory feedIDs, uint256[] memory timestampstart, uint256[] memory timestampfinish, bool strictMode) external view returns (uint256[] memory TWAP) {

            uint256 feedLen = feedIDs.length;
            TWAP = new uint256[](feedLen);
            uint256[] memory timeslot = new uint256[](feedLen);

            require(feedIDs.length == timestampstart.length && feedIDs.length == timestampfinish.length, "Feeds and Timestamps must match");

            (,,timeslot,,) = OOFContract.getFeedList(feedIDs);

            for (uint c = 0; c < feedLen; c++) {

                uint256 twapCount = timestampfinish[c] / timeslot[c] - timestampstart[c] / timeslot[c] + 1;
                uint256[] memory twapFeedIDs = new uint256[](twapCount);
                uint256[] memory timestampToCheck = new uint256[](twapCount);
                uint256 twapTotal;

                uint256[] memory totals = new uint256[](twapCount);

                for (uint s = 0; s < twapCount; s++) {
                    timestampToCheck[s] = timestampstart[c] + s * timeslot[c];
                    twapFeedIDs[s] = feedIDs[c];
                }

                totals = OOFContract.getHistoricalFeeds(twapFeedIDs, timestampToCheck);

                uint256 twapLen;

                if (strictMode) {
                    require(totals[0] != 0 && totals[totals.length-1] != 0, "Strict Mode: no 0 values for first and last element");
                }

                for (uint t = 0; t < totals.length; t++){
                    if (totals[t] != 0) {
                        twapTotal += totals[t];
                        twapLen += 1;
                    }
                }

                if (twapLen > 0) {
                    TWAP[c] = twapTotal / twapLen;
                } else {
                    TWAP[c] = 0;
                }
            }

            return (TWAP);
    }

    function lastTWAP(IOpenOracleFramework OOFContract, uint256[] memory feedIDs, uint256[] memory timeWindows) external view returns (uint256[] memory TWAP) {

        TWAP = new uint256[](feedIDs.length);
        uint256[] memory timeslot = new uint256[](feedIDs.length);

        (,,timeslot,,) = OOFContract.getFeedList(feedIDs);

        for (uint c = 0; c < feedIDs.length; c++) {
            uint256 timestampfinish = block.timestamp;
            uint256 timestampstart = timestampfinish - timeWindows[c];

            uint256 twapCount = timestampfinish / timeslot[c] - timestampstart / timeslot[c] + 1;
            uint256[] memory twapFeedIDs = new uint256[](twapCount);
            uint256[] memory timestampToCheck = new uint256[](twapCount);
            uint256 twapTotal;

            uint256[] memory totals = new uint256[](twapCount);

            for (uint s = 0; s < twapCount; s++) {
                timestampToCheck[s] = timestampstart + s * timeslot[c];
                twapFeedIDs[s] = feedIDs[c];
            }

            totals = OOFContract.getHistoricalFeeds(twapFeedIDs, timestampToCheck);

            uint256 twapLen;

            for (uint t = 0; t < totals.length; t++){
                if (totals[t] != 0) {
                    twapTotal += totals[t];
                    twapLen += 1;
                }
            }

            if (twapLen > 0) {
                uint256 feedValue;
                (feedValue,,) = OOFContract.getFeed(feedIDs[c]);
                TWAP[c] = (twapTotal + feedValue) / (twapLen + 1);
            } else {
                TWAP[c] = 0;
            }
        }

        return (TWAP);
    }
}