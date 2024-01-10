// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

import "./LibAppStorage.sol";

library LibBidderQueue {
    function _init(BidderQueue storage _queue) internal {
        _queue.head = 1;
    }

    function _isEmpty(BidderQueue storage _queue) internal view returns (bool _result) {
        return _queue.tail < _queue.head;
    }

    function _size(BidderQueue storage _queue) internal view returns (uint128 _result) {
        return _queue.tail + 1 - _queue.head ;
    }

    function _enqueue(BidderQueue storage _queue, address _bidder) internal returns (uint64 _expiry) {
        _expiry = uint64(block.timestamp) + LibAppStorage._diamondStorage().bidTimeout;
        _queue.queue[++_queue.tail] = BidderAndTimeOut(_bidder, _expiry);
    }

    function _dequeue(BidderQueue storage _queue) internal {
        require(!_isEmpty(_queue));
        delete _queue.queue[_queue.head++];
    }

    function _peek(BidderQueue storage _queue) internal view returns (address _bidder, uint256 _timeOut) {
        require(!_isEmpty(_queue));
        (_bidder, _timeOut) = (_queue.queue[_queue.head].bidder, _queue.queue[_queue.head].timeOut);
    }

    function _get(
        BidderQueue storage _queue,
        uint128 _index
    ) internal view returns (
        address _bidder,
        uint256 _timeOut
    ) {
        require(_index < _size(_queue));
        (_bidder, _timeOut) = (_queue.queue[_queue.head + _index].bidder, _queue.queue[_queue.head + _index].timeOut);
    }
}
