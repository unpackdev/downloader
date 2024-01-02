// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import "./Structs.sol";

///@title RequestQueue contract
///@notice Handle the logic for the request queue
abstract contract RequestQueue {
  /*//////////////////////////////////////////////////////////////
                                 STORAGE
    //////////////////////////////////////////////////////////////*/

  ///@notice Request queue
  RequestQ internal requestQueue;

  /*//////////////////////////////////////////////////////////////
                                 ERROR
    //////////////////////////////////////////////////////////////*/
  error EmptyQueue();
  error NotEnoughRequests();

  /*//////////////////////////////////////////////////////////////
                                 GETTERS
    //////////////////////////////////////////////////////////////*/

  ///@notice Return the request, to get the first request pass 0 as index
  ///@dev return arbitrary requests in queue by providing the desired index e.g. 0 => first element
  /// in queue
  function getRequest(uint64 idx) public view returns (RequestData memory) {
    return requestQueue.requestData[requestQueue.start + idx];
  }

  ///@notice Return the number of pending request
  function getNumPendingRequest() public view returns (uint256) {
    return requestQueue.end - requestQueue.start;
  }

  /*//////////////////////////////////////////////////////////////
                                 INTERNAL
    //////////////////////////////////////////////////////////////*/

  ///@dev Add request to the end of the queue
  ///@param _newRequest: RequestData - data to be added to the queue
  function _enqueueRequest(RequestData memory _newRequest) internal {
    requestQueue.requestData[requestQueue.end++] = _newRequest;
  }

  ///@dev removes and returns request from the beginning of the queue
  function _dequeueRequest() internal returns (RequestData memory) {
    uint64 start = requestQueue.start++;

    if (start == requestQueue.end) revert EmptyQueue();
    RequestData memory firstRequest = requestQueue.requestData[start];
    delete requestQueue.requestData[start];
    return firstRequest;
  }

  ///@dev removes and returns request from the beginning of the queue
  function _deleteRequests(uint64 _numRequests) internal {
    if (_numRequests > getNumPendingRequest()) revert NotEnoughRequests();
    uint64 start = requestQueue.start;
    uint64 end = start + _numRequests;

    while (start < end) {
      delete requestQueue.requestData[start];
      start++;
    }
    requestQueue.start = start;
  }
}
