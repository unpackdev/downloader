// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Random  {

    // Pending count
    uint256 private pendingCount;
    // Pending Ids
    uint256[] private _pendingIds;

    constructor(uint _pendingCount) {
        pendingCount = _pendingCount;
        _pendingIds = new uint256[](_pendingCount+1);
    }

    function _getRandomNFTTokenID() internal returns (uint256){
        uint256 index = (_getRandom() % pendingCount) + 1;
        uint256 tokenId = _popPendingAtIndex(index);
        return tokenId;
    }

    function _getNextRemainingTokenID() internal returns (uint256){
        uint256 index =  pendingCount ;
        uint256 tokenId = _popPendingAtIndex(index);
        return tokenId;
    }

    function _getPendingAtIndex(uint256 _index) private view returns (uint256) {
        return _pendingIds[_index] + _index;
    }

    function _popPendingAtIndex(uint256 _index) private returns (uint256) {
        uint256 tokenId = _getPendingAtIndex(_index);
        if (_index != pendingCount) {
            uint256 lastPendingId = _getPendingAtIndex(pendingCount);
            _pendingIds[_index] = lastPendingId - _index;
        }
        pendingCount--;
        return tokenId;
    }

    function _getRandom() private view returns(uint256) {
        uint256 seed = uint256(keccak256(abi.encodePacked(
            block.timestamp + block.difficulty +
            ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
            block.gaslimit + 
            ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) +
            block.number+
            pendingCount
        )));
        return seed;
    }
}