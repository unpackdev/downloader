// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./DapiReader.sol";
import "./ISelfServeDapiServerWhitelister.sol";
import "./IDapiServer.sol";
import "./IWhitelistWithManager.sol";

contract SelfServeDapiServerWhitelister is
    DapiReader,
    ISelfServeDapiServerWhitelister
{
    constructor(address _dapiServer) DapiReader(_dapiServer) {}

    function allowToReadDataFeedWithIdFor30Days(
        bytes32 dataFeedId,
        address reader
    ) public override {
        (uint64 expirationTimestamp, ) = IDapiServer(dapiServer)
            .dataFeedIdToReaderToWhitelistStatus(dataFeedId, reader);
        uint64 targetedExpirationTimestamp = uint64(block.timestamp + 30 days);
        if (targetedExpirationTimestamp > expirationTimestamp) {
            IWhitelistWithManager(dapiServer).extendWhitelistExpiration(
                dataFeedId,
                reader,
                targetedExpirationTimestamp
            );
        }
    }

    function allowToReadDataFeedWithDapiNameFor30Days(
        bytes32 dapiName,
        address reader
    ) external override {
        allowToReadDataFeedWithIdFor30Days(
            keccak256(abi.encodePacked(dapiName)),
            reader
        );
    }
}
