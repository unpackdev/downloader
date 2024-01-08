// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./console.sol";

interface IECRegistry {
    function getImplementer(uint16 traitID) external view returns (address);
    function addressCanModifyTrait(address, uint16) external view returns (bool);
    function addressCanModifyTraits(address, uint16[] memory) external view returns (bool);
    function hasTrait(uint16 traitID, uint16 tokenID) external view returns (bool);
    function setTrait(uint16 traitID, uint16 tokenID, bool) external;
}

contract TokenSetRangeWithDataUpdate is Ownable {

    bytes32                     public name;
    uint256                     public actualSize;
    uint16                      public start;
    uint16                      public end;
    uint8                       public setType = 3;

    mapping(uint16 => uint16)   public data;

    IECRegistry                 public ECRegistry;
    uint16            immutable public traitId;

    /**
     * Virtual range data set, ordering not guaranteed because removal 
     * just replaces position with last item and decreases collection size
     *
     *  - data stored after range end.
     *  - range is readonly, data after can be altered.
     *
     */
    constructor(bytes32 _name, uint16 _start, uint16 _end, address _registry, uint16 _traitId) {
        name = _name;
        start = _start;
        end = _end;
        actualSize = _end - _start + 1;

        traitId = _traitId;
        ECRegistry = IECRegistry(_registry);
    }

    /**
     * @notice Add a token to the end of the list
     */
    function add(uint16 _id) public onlyAllowed {
        data[uint16(actualSize)] = _id;
        actualSize++;
    }

    /**
     * @notice Add a token to the end of the list
     */
    function batchAdd(uint16[] calldata _id) public onlyAllowed {
        for(uint16 i = 0; i < _id.length; i++) {
            data[uint16(actualSize++)] = _id[i];
        }
    }

    /**
     * @notice Remove the token at virtual position if present in data
     */
    function remove(uint32 _pos, uint16 _permille) public onlyAllowed {
        uint16 realPosition = getInternalPosition(_pos, _permille);
        require(realPosition > end && realPosition < actualSize + end - start + 1, "TokenSetRange: Position out of data bounds.");
        // copy value of last item in set to position and decrease length by 1
        actualSize--;
        data[realPosition - start] = data[uint16(actualSize)];
    }

    /**
     * @notice Get the token at virtual position
     */
    function get(uint32 _pos, uint16 _permille) public view returns (uint16) {
        uint16 realPosition = getInternalPosition(_pos, _permille);
        if(realPosition >= start && realPosition <= end) {
            return realPosition;
        }
        return data[realPosition - start];
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

    modifier onlyAllowed() {
        require(
            ECRegistry.addressCanModifyTrait(msg.sender, traitId),
            "TokenSet: Not Authorised" 
        );
        _;
    }

}