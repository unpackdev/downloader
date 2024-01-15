// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./IDapiReader.sol";

interface ISelfServeDapiServerWhitelister is IDapiReader {
    function allowToReadDataFeedWithIdFor30Days(bytes32 dataFeedId, address reader)
        external;

    function allowToReadDataFeedWithDapiNameFor30Days(bytes32 dapiName, address reader)
        external;
}
