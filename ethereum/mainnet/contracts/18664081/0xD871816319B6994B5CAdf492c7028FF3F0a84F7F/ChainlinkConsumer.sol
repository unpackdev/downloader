// SPDX-License-Identifier: MIT
// An example of a consumer contract that directly pays for each request.
pragma solidity ^0.8.7;

import "./ConfirmedOwner.sol";
import "./VRFV2WrapperConsumerBase.sol";

contract VRFv2DirectFundingConsumer is VRFV2WrapperConsumerBase, ConfirmedOwner {
    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256 randomWord, uint256 payment);

    struct RequestStatus {
        uint256 paid; // amount paid in link
        bool fulfilled; // whether the request has been successfully fulfilled
        uint256 winner;
    }

    mapping(uint256 => RequestStatus) public s_requests; /* requestId --> requestStatus */
    mapping(uint256 => uint256) public winners;
    // past requests Id.
    uint256[] public requestIds;
    uint256 public lastRequestId;
    uint256 public listLength;
    uint256 public lastRequestTimestamp;

    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    // function.
    uint32 callbackGasLimit = 100_000;

    // The default is 3, but you can set this higher.
    uint16 requestConfirmations = 3;

    uint32 numWords = 1;

    address public immutable linkAddress;

    error TooEarly();

    constructor(
        address _linkAddress,
        address _wrapperAddress,
        address _owner
    )
        ConfirmedOwner(_owner)
        VRFV2WrapperConsumerBase(_linkAddress, _wrapperAddress)
    {
        linkAddress = _linkAddress;
    }

    function requestWinner(uint256 _listLength) external onlyOwner returns (uint256 requestId) {
        if (lastRequestTimestamp + 1 days > block.timestamp) revert TooEarly();
        listLength = _listLength;
        requestId = requestRandomness(callbackGasLimit, requestConfirmations, numWords);
        s_requests[requestId] =
            RequestStatus({ paid: VRF_V2_WRAPPER.calculateRequestPrice(callbackGasLimit), winner: 0, fulfilled: false });
        requestIds.push(requestId);
        lastRequestId = requestId;
        lastRequestTimestamp = (block.timestamp / 1 days) * 1 days;

        emit RequestSent(requestId, numWords);
        return requestId;
    }

    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        require(s_requests[_requestId].paid > 0, "request not found");
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].winner = _randomWords[0] % listLength;
        winners[lastRequestTimestamp] = _randomWords[0] % listLength;
        emit RequestFulfilled(_requestId, _randomWords[0] % listLength, s_requests[_requestId].paid);
    }

    function getRequestStatus(uint256 _requestId)
        external
        view
        returns (uint256 paid, bool fulfilled, uint256 winner)
    {
        require(s_requests[_requestId].paid > 0, "request not found");
        RequestStatus memory request = s_requests[_requestId];
        return (request.paid, request.fulfilled, request.winner);
    }

    /**
     * Allow withdraw of Link tokens from the contract
     */
    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(linkAddress);
        require(link.transfer(msg.sender, link.balanceOf(address(this))), "Unable to transfer");
    }
}
