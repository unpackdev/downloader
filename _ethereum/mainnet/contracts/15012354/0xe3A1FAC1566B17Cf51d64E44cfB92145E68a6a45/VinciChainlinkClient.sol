// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ChainlinkClient.sol";
import "./LinkTokenInterface.sol";

import "./Operatable.sol";
import "./VinciCollectPriceCumulative.sol";

/**
 * Request testnet LINK and ETH here: https://faucets.chain.link/
 * Find information on LINK Token Contracts and get the latest ETH and LINK faucets here: https://docs.chain.link/docs/link-token-contracts/
 */

/**
 * THIS IS AN EXAMPLE CONTRACT WHICH USES HARDCODED VALUES FOR CLARITY.
 * PLEASE DO NOT USE THIS CODE IN PRODUCTION.
 */
contract VinciChainlinkClient is ChainlinkClient, Operatable {
    using Chainlink for Chainlink.Request;

    struct Node {
        uint8 nodeId;
        address oracle;
        bytes32 jobId;
        uint256 fee;
        string url;
        string path;
    }
    uint8 internal nodeIndex = 0;
    
    mapping(address => Node) internal nodes;
    mapping(bytes32 => address) private collectors;

    event VinciChainlinkFulfilled(uint8 indexed id, uint64 time, int256 _data);

    /**
     * Network: Kovan
     * Oracle: 0xc57B33452b4F7BB189bB5AfaE9cc4aBa1f7a4FD8 (Chainlink Devrel   
     * Node)
     * Job ID: d5270d1c311941d0b08bead21fea7747
     * Fee: 0.1 LINK 0.1 * 10 ** 18
     */
    constructor(address _link) {
        setChainlinkToken(_link);
    }
    
    /**
     * Create a Chainlink request to retrieve API response, find the target
     * data, then multiply by 1000000000000000000 (to remove decimal places from data).
     */
    function requestVolumeData(address _collector) public onlyOperator returns (bytes32 requestId) 
    {
        require(nodes[_collector].oracle != address(0x0), "please update nodes");
        Chainlink.Request memory request = buildChainlinkRequest(nodes[_collector].jobId, address(this), this.fulfill.selector);
        
        // Set the URL to perform the GET request on
        request.add("get", nodes[_collector].url);
        request.add("path", nodes[_collector].path);
        
        // Multiply the result by 1000000000000000000 to remove decimals
        int timesAmount = 10**18;
        request.addInt("times", timesAmount);
        
        // Sends the request
        bytes32 Id = sendChainlinkRequestTo(nodes[_collector].oracle, request, nodes[_collector].fee);
        collectors[Id] = _collector;
        return Id;
    }
    
    /**
     * Receive the response in the form of uint256
     */
    function fulfill(bytes32 _requestId, int256 _data) public recordChainlinkFulfillment(_requestId)
    {
        address collector = collectors[_requestId];
        VinciCollectPriceCumulative(collector).updatePriceCumulative(_data);
        delete collectors[_requestId];
        emit VinciChainlinkFulfilled(nodes[collector].nodeId, uint64(block.timestamp), _data);
    }

    function setNode(
        address _collector,
        address _oracle,
        bytes32 _jobId,
        uint256 _fee,
        string memory _url,
        string memory _path
        ) public onlyOwner {
        if (nodes[_collector].nodeId == 0) {
          nodeIndex = nodeIndex + 1;
          nodes[_collector].nodeId = nodeIndex;
        }
        nodes[_collector].oracle = _oracle;
        nodes[_collector].jobId = _jobId;
        nodes[_collector].fee = _fee;
        nodes[_collector].url = _url;
        nodes[_collector].path = _path;
    }

    function getNode(address _collector) public view
        returns (
        uint8 nodeId,
        address oracle,
        bytes32 jobId,
        uint256 fee,
        string memory url,
        string memory path
        )
    {
        Node memory n = nodes[_collector];
        return (
        n.nodeId,
        n.oracle,
        n.jobId,
        n.fee,
        n.url,
        n.path
        );
    }

   function LinkBalanceOf() public view returns (uint256) {
       LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
       return link.balanceOf(address(this));
   }

   function withdrawAllLink() public onlyOwner {
       uint256 amount = LinkBalanceOf();
       LinkTokenInterface(chainlinkTokenAddress()).transfer(msg.sender, amount);
   }
}
