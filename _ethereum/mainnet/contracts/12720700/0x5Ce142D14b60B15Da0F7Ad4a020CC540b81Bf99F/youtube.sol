   // SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

 //import "./ChainlinkClient.sol";
import "./ChainlinkClient.sol";


contract ChainlinkYoutube is ChainlinkClient{
    address private oracle;
    bytes32 private jobId1;
    bytes32 private jobId2;
    uint256 private fee;
    address private Owner;

    struct uriDetails{
        uint256 token_id;
        string uri;
        uint256 dynamicRating;
        uint256 followerCount;
        uint256 youtubeSub;
    }
    mapping (uint256 => uriDetails) internal dataInfo;
    
    struct reqData{
        uint256 token_id;
        bytes32 reqID1;
        bytes32 reqID2;
    }
    mapping (bytes32 => reqData) private reqInfo;

    constructor() public {
    	setPublicChainlinkToken();
    	oracle = 0x2EAD1016d3F4cE809a299691aCC3df2eD5434290; // oracle address
    	jobId1 = "8545e40611eb4f64aabeee93cd68e7ed"; //job id twitter adapter
    	jobId2 = "251907056cc04b01b08dd84f6b17b54a"; //job id youtube adapter
    	Owner = msg.sender;
    	fee = 1; 
    }
    
    function updateFollowerCount(uint256 _tokenId, string memory username, string memory id) public returns (bytes32 requestId1, bytes32 requestId2){
        require(msg.sender == Owner,"ChainlinkUpdate: You are not owner");
    	Chainlink.Request memory req1 = buildChainlinkRequest(jobId1, address(this), this.twitterFullfill.selector);
    	Chainlink.Request memory req2 = buildChainlinkRequest(jobId2, address(this), this.youtubeFullfill.selector);
    	req1.add("value", username);
    	req2.add("id", id);
    	requestId1 = sendChainlinkRequestTo(oracle, req1, fee);
    	requestId2 = sendChainlinkRequestTo(oracle, req2, fee);
        reqData storage data1 = reqInfo[requestId1];
        reqData storage data2 = reqInfo[requestId2];
        data1.token_id = _tokenId;
        data1.reqID1 = requestId1;
        data2.token_id = _tokenId;
        data2.reqID2 = requestId2;
    	return (requestId1, requestId2);
    }
    
    function twitterFullfill(bytes32 _requestId1, uint256 _followerCount) public recordChainlinkFulfillment(_requestId1) {
        uint256 _tokenID = viewTokenId(_requestId1);
        uriDetails storage data = dataInfo[_tokenID];
        data.token_id = _tokenID;
        data.followerCount = _followerCount;
    }
    
    function youtubeFullfill(bytes32 _requestId2, uint256 _youtubeSub) public recordChainlinkFulfillment(_requestId2){
        uint256 _tokenID = viewTokenId(_requestId2);
        uriDetails storage data = dataInfo[_tokenID];
        data.youtubeSub = _youtubeSub;
    }
    
    function viewTokenDetails(uint256 _tokenId) view public returns(uint256,string memory, uint256, uint256, uint256){
        return(dataInfo[_tokenId].token_id, dataInfo[_tokenId].uri, dataInfo[_tokenId].dynamicRating, dataInfo[_tokenId].followerCount, dataInfo[_tokenId].youtubeSub);
    }
    
    function viewTokenId(bytes32 reqID) internal returns(uint256){
        return(reqInfo[reqID].token_id);
    }
    
    function withdrawLink() public {
        require(msg.sender == Owner,"ChainlinkUpdate: You are not owner");
        LinkTokenInterface linkToken = LinkTokenInterface(chainlinkTokenAddress());
        require(linkToken.transfer(msg.sender, linkToken.balanceOf(address(this))), "Unable to transfer");
    }
}    