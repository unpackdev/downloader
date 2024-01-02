// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ChainlinkClient.sol";
import "./Ownable.sol";

contract ChainlinkTweetRetriever is ChainlinkClient, Ownable {
    using Chainlink for Chainlink.Request;

    string public latestTweet;
    address private oracle;
    bytes32 private jobId;
    uint256 private fee;

   
    constructor(address _oracle, string memory _jobId, uint256 _fee)
        Ownable(msg.sender) 
    {
        setPublicChainlinkToken();
        oracle = _oracle;
        jobId = stringToBytes32(_jobId);
        fee = _fee;
    }

    // Function to initiate a Chainlink request
    function requestLatestTweet(string memory _twitterUsername) public onlyOwner {
        Chainlink.Request memory req = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);
        req.add("twitterUsername", _twitterUsername);
        sendChainlinkRequestTo(oracle, req, fee);
    }

    // Callback function that receives the tweet data
    function fulfill(bytes32 _requestId, string memory _tweet) public recordChainlinkFulfillment(_requestId) {
        latestTweet = _tweet;
    }

    // Helper function to convert string to bytes32
    function stringToBytes32(string memory source) private pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }

   
}

