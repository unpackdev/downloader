// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./console.sol";

contract TokenSetRangeReadonly is Ownable {

    bytes32     public name;
    uint256     public actualSize;
    uint16      public start;
    uint16      public end;
    uint8       public setType = 2;

    /**
     * Virtual range data set, ordering not guaranteed because removal 
     * just replaces position with last item and decreases collection size
     */
    constructor(bytes32 _name, uint16 _start, uint16 _end) {
        name = _name;
        start = _start;
        end = _end;
        actualSize = _end - _start + 1;
    }

    /**
     * @notice Get the token at virtual position
     */
    function get(uint32 _pos, uint16 _permille) public view returns (uint16) {
        return getInternalPosition(_pos, _permille);
    }

    /**
     * @notice Retrieve list size
     */
    function size(uint16 _permille) public view returns (uint256) {
        return actualSize * _permille;
    }

    /**
     * @notice Retrieve internal position for a virtual position
     */
    function getInternalPosition(uint32 _pos, uint16 _permille) public view returns(uint16) {
        uint256 realPosition = _pos / _permille + start;
        require(realPosition < actualSize + start, "TokenSetRange: Index out of bounds.");
        return uint16(realPosition);
    }

    /**
     * @notice Retrieve set info
     */
    function info() public view returns (bytes32 _name, uint256 _actualSize, uint16 _start, uint16 _end) {
        return (
            name,
            actualSize,
            start,
            end
        );
    }

}