// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Context.sol";

abstract contract RandomPoolId is Context {
    // Minimum value of the ids range
    uint256 internal immutable _minId;
    // Maximum value of the ids range
    uint256 private immutable _maxId;
    // Size of the actual range of available ids
    uint256 internal _rangeLength;
    // TokenID cache for random id generation
    mapping(uint256 => uint256) private _swappedIds;

    constructor(uint256 minId, uint256 maxId) {
        _minId = minId;
        _maxId = maxId;
        _rangeLength = maxId - minId;
    }

    function _randomize() internal virtual returns (uint256) {
        require(_rangeLength > 0, 'Randomize: cannot pick another id as they where all picked already');
        uint256 randomIndex = _randomNumber(0, _rangeLength);
        uint256 id = _swappedIds[randomIndex];

        if (id == 0) {
            id = randomIndex;
        }

        // Swap last one with the picked one.
        // Last one can be a previously picked one as well, thats why we check.
        if (_swappedIds[_rangeLength - 1] == 0) {
            _swappedIds[randomIndex] = _rangeLength - 1;
        } else {
            _swappedIds[randomIndex] = _swappedIds[_rangeLength - 1];
        }
        _rangeLength--;

        return id + _minId;
    }

    /**
     * Function to generate a random number within a given range.
     * @param min min range for the random number.
     * @param max max range for the random number.
     */
    function _randomNumber(uint256 min, uint256 max) internal view virtual returns (uint256) {
        require(max >= min, 'RandomNumber: invalid range');
        uint256 randNumber = uint256(
            keccak256(abi.encodePacked(block.prevrandao, block.timestamp, _msgSender(), blockhash(block.number)))
        ) % (max - min + 1);
        return randNumber + min;
    }

    function maxSupply() public view returns (uint256) {
        return _maxId - _minId;
    }
}
