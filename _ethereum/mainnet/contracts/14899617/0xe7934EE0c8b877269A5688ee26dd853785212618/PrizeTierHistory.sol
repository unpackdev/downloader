// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;
import "./Manageable.sol";
import "./IPrizeTierHistory.sol";
import "./BinarySearchLib.sol";

/**
 * @title  PoolTogether V4 PrizeTierHistory
 * @author PoolTogether Inc Team
 * @notice The PrizeTierHistory smart contract stores a history of PrizeTier structs linked to 
           a range of valid Draw IDs. 
 * @dev    If the history param has single PrizeTier struct with a "drawId" of 1 all subsequent
           Draws will use that PrizeTier struct for PrizeDitribution calculations. The BinarySearchLib
           will find a PrizeTier using a "atOrBefore" range search when supplied drawId input parameter.
 */
contract PrizeTierHistory is IPrizeTierHistory, Manageable {

    // @dev The uint32[] type is extended with a binarySearch(uint32) function.
    using BinarySearchLib for uint32[];

    /**
     * @notice Ordered array of Draw IDs
     * @dev The history, with sequentially ordered ids, can be searched using binary search.
            The binary search will find index of a drawId (atOrBefore) using a specific drawId (at).
            When a new Draw ID is added to the history, a corresponding mapping of the ID is 
            updated in the prizeTiers mapping.
    */
    uint32[] internal history;

    /**
     * @notice Mapping a Draw ID to a PrizeTier struct.
     * @dev The prizeTiers mapping links a Draw ID to a PrizeTier struct.
            The prizeTiers mapping is updated when a new Draw ID is added to the history.
    */
    mapping(uint32 => PrizeTier) internal prizeTiers;

    constructor(address owner) Ownable(owner) {}

    // @inheritdoc IPrizeTierHistory
    function count() external view override returns (uint256) {
        return history.length;
    }
    
    // @inheritdoc IPrizeTierHistory
    function getOldestDrawId() external view override returns (uint32) {
        return history[0];
    }

    // @inheritdoc IPrizeTierHistory
    function getNewestDrawId() external view override returns (uint32) {
        return history[history.length - 1];
    }

    // @inheritdoc IPrizeTierHistory
    function getPrizeTier(uint32 drawId) override external view returns (PrizeTier memory) {
        require(drawId > 0, "PrizeTierHistory/draw-id-not-zero");
        return prizeTiers[history.binarySearch(drawId)];
    }

    // @inheritdoc IPrizeTierHistory
    function getPrizeTierList(uint32[] calldata _drawIds) override external view returns (PrizeTier[] memory) {
        uint256 _length = _drawIds.length; 
        PrizeTier[] memory _data = new PrizeTier[](_length);
        for (uint256 index = 0; index < _length; index++) {
            _data[index] = prizeTiers[history.binarySearch(_drawIds[index])];
        }
        return _data;
    }

    // @inheritdoc IPrizeTierHistory
    function getPrizeTierAtIndex(uint256 index) external view override returns (PrizeTier memory) {
        return prizeTiers[uint32(index)];
    }

    // @inheritdoc IPrizeTierHistory
    function push(PrizeTier calldata nextPrizeTier) override external onlyManagerOrOwner {
        _push(nextPrizeTier);
    }
    
    // @inheritdoc IPrizeTierHistory
    function popAndPush(PrizeTier calldata newPrizeTier) override external onlyOwner returns (uint32) {
        uint length = history.length;
        require(length > 0, "PrizeTierHistory/history-empty");
        require(history[length - 1] == newPrizeTier.drawId, "PrizeTierHistory/invalid-draw-id");
        _replace(newPrizeTier);
        return newPrizeTier.drawId;
    }

    // @inheritdoc IPrizeTierHistory
    function replace(PrizeTier calldata newPrizeTier) override external onlyOwner {
        _replace(newPrizeTier);
    }

    function _push(PrizeTier memory _prizeTier) internal {
        uint32 _length = uint32(history.length);
        if (_length > 0) {
            uint32 _id = history[_length - 1];
            require(
                _prizeTier.drawId > _id,
                "PrizeTierHistory/non-sequential-id"
            );
        }
        history.push(_prizeTier.drawId);
        prizeTiers[_length] = _prizeTier;
        emit PrizeTierPushed(_prizeTier.drawId, _prizeTier);
    }

    function _replace(PrizeTier calldata _prizeTier) internal {
        uint256 cardinality = history.length;
        require(cardinality > 0, "PrizeTierHistory/no-prize-tiers");
        uint32 oldestDrawId = history[0];
        require(_prizeTier.drawId >= oldestDrawId, "PrizeTierHistory/draw-id-out-of-range");
        uint32 index = history.binarySearch(_prizeTier.drawId);
        require(history[index] == _prizeTier.drawId, "PrizeTierHistory/draw-id-must-match");
        prizeTiers[index] = _prizeTier;
        emit PrizeTierSet(_prizeTier.drawId, _prizeTier);
    }
}
