// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ChainlinkClient.sol";
import "./Ownable.sol";

/// @author The Cache Gold Team
/// @title This contract consumes the Cache Gold Oracle web2.0 API and is in turn called by CacheGoldLockedDataCronKeeper.sol
contract LockedCacheGoldAPIConsumer is ChainlinkClient, Ownable {
    using Chainlink for Chainlink.Request;
    uint256 public lockedGold;
    
    // Private variable naming convention as per template contract
    address private oracle;
    bytes32 private jobId;
    uint256 private fee;

    /**
     * @dev set the initial oracle and job ID
     * @param _oracle This is the address of the oracle registered with chainlink
     * @param _jobId This is the jobid from the list of jobs available in our case it is a HTTP GET request
     */ 
    constructor(address _oracle, bytes32 _jobId) {
        setPublicChainlinkToken();
        oracle = _oracle;
        jobId = _jobId;
        fee = 0.1 * 10 ** 18; // 0.1 LINK
    }

    /**
     * Set oracle address locally
     * @dev Since we use sendChainlinkRequestTo instead of sendChainlinkRequest we set this locally
     * @param _oracle  This is the address of the oracle registered with chainlink
     */ 
    function setOracle(address _oracle) external onlyOwner {
        require(_oracle != address(0)); //Check that it is not the zeroth address
        oracle = _oracle;
    }
    
    /**
     * Set fees, this is the fees that is paid in tribute to the service offered
     * @param _fee the fee in uint256 here it should be 0.01 Link
     */ 
    function setFees(uint256 _fee) external onlyOwner {
        require(_fee > 0);
        fee = _fee;
    }

    /**
     * Set the job id
     * @param _jobId This is the jobid from the list of jobs available in our case it is a HTTP GET request
     */ 
    function setJobId(bytes32 _jobId) external onlyOwner {
        jobId = _jobId;
    }

    /**
     * Get the oracle
     * @return oracleAddress 
     */ 
    function getOracle() external view returns(address oracleAddress) {
        return oracle;
    }

    /**
     * Get the feeAmount that is in LINK tokens
     * @return feeAmount
     */ 
    function getFees() external view returns(uint256 feeAmount) {
        return fee;
    }

    /**
     * Get the jobId
     * @return jobIdentifier
     */ 
    function getJobId() external view returns(bytes32 jobIdentifier) {
        return jobId;
    }

    /**
     * Receive the response in the form of requestId
     * @dev Kept pathOfValue as dynamic in case the path changes in future or we want to accomodate more in the same link
     * @param _pathOfValue This is the path of the value in the json object response in the url
     */ 
    function requestedLockedData(string memory _pathOfValue) public returns (bytes32 requestId) 
    {
        require(bytes(_pathOfValue).length != 0, "Requested path is not valid");
        
        Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);
        
        // use 8 decimals for Cache Gold Token
        request.add("get", "https://contract.cache.gold/api/lockedGold");
        request.add("path", _pathOfValue);
        int timesAmount = 10**8;
        request.addInt("times", timesAmount);
        // Sends the request
        requestId = sendChainlinkRequestTo(oracle, request, fee);
        return requestId;
    }
    
    /**
     * Fulfill the http request by the chainlink oracle
     * @dev set condition that there should be some minimum locked gold
     * @param _requestId This is the request ID that was created in requestedLockedData
     * @param _lockedGold This is the amount of locked gold from the api call
     */ 
    function fulfill(bytes32 _requestId, uint256 _lockedGold) public recordChainlinkFulfillment(_requestId)
    {
        require(_lockedGold >= 1, "Locked Gold has to have a value greater than or equal to 1");
        lockedGold = _lockedGold;
    }

    /**
     * An option to withdraw LINK tokens in case of emergency
     */ 
    function withdrawLINK() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(link.transfer(msg.sender, link.balanceOf(address(this))), "Unable to transfer");
    }
    
}