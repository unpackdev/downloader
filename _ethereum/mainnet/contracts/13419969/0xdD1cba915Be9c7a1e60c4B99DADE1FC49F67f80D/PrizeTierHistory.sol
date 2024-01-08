// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;

import "./Manageable.sol";
import "./IPrizeTierHistory.sol";

/**
 * @title  PoolTogether V4 IPrizeTierHistory
 * @author PoolTogether Inc Team
 * @notice IPrizeTierHistory is the base contract for PrizeTierHistory
 */
contract PrizeTierHistory is IPrizeTierHistory, Manageable {
    
    /* ============ Global Variables ============ */
    /**
     * @notice History of PrizeTier updates
     */
    PrizeTier[] internal history;

    /* ============ Constructor ============ */
    constructor(address _owner) Ownable(_owner) {}

    /* ============ External Functions ============ */

    // @inheritdoc IPrizeTierHistory
    function push(PrizeTier calldata _nextPrizeTier)
        external
        override
        onlyManagerOrOwner
        returns (uint32)
    {
        PrizeTier[] memory _history = history;

        if (_history.length > 0) {
            // READ the newest PrizeTier struct
            PrizeTier memory _newestPrizeTier = history[history.length - 1];
            // New PrizeTier ID must only be 1 greater than the last PrizeTier ID.
            require(
                _nextPrizeTier.drawId > _newestPrizeTier.drawId,
                "PrizeTierHistory/non-sequential-prize-tier"
            );
        }

        history.push(_nextPrizeTier);

        emit PrizeTierPushed(_nextPrizeTier.drawId, _nextPrizeTier);
    }

    // @inheritdoc IPrizeTierHistory
    function replace(PrizeTier calldata _prizeTier) external override onlyOwner returns (uint256) {
        uint256 cardinality = history.length;
        require(cardinality > 0, "PrizeTierHistory/no-prize-tiers");

        uint256 leftSide = 0;
        uint256 rightSide = cardinality - 1;
        uint32 oldestDrawId = history[leftSide].drawId;
        uint32 newestDrawId = history[rightSide].drawId;

        require(_prizeTier.drawId >= oldestDrawId, "PrizeTierHistory/draw-id-out-of-range");

        uint256 index = _binarySearchIndex(_prizeTier.drawId, leftSide, rightSide, history);

        require(history[index].drawId == _prizeTier.drawId, "PrizeTierHistory/draw-id-must-match");

        history[index] = _prizeTier;

        emit PrizeTierSet(_prizeTier.drawId, _prizeTier);
    }

    /* ============ Setter Functions ============ */

    // @inheritdoc IPrizeTierHistory
    function popAndPush(PrizeTier calldata _prizeTier) external override onlyOwner returns (uint32) {
      require(history.length > 0, "PrizeTierHistory/history-empty");
      PrizeTier memory _newestPrizeTier = history[history.length - 1];
      require(_prizeTier.drawId >= _newestPrizeTier.drawId, "PrizeTierHistory/invalid-draw-id");
      history[history.length - 1] = _prizeTier;
      emit PrizeTierSet(_prizeTier.drawId, _prizeTier);

      return _prizeTier.drawId;
    }

    /* ============ Getter Functions ============ */

    // @inheritdoc IPrizeTierHistory
    function getPrizeTier(uint32 _drawId) external view override returns (PrizeTier memory) {
        require(_drawId > 0, "PrizeTierHistory/draw-id-not-zero");
        return _getPrizeTier(_drawId);
    }
    // @inheritdoc IPrizeTierHistory
    function getOldestDrawId() external view override returns (uint32) {
        return history[0].drawId;
    }

    // @inheritdoc IPrizeTierHistory
    function getNewestDrawId() external view override returns (uint32) {
        return history[history.length - 1].drawId;
    }

    // @inheritdoc IPrizeTierHistory
    function getPrizeTierList(uint32[] calldata _drawIds)
        external
        view
        override
        returns (PrizeTier[] memory)
    {
        PrizeTier[] memory _data = new PrizeTier[](_drawIds.length);
        for (uint256 index = 0; index < _drawIds.length; index++) {
          _data[index] = _getPrizeTier(_drawIds[index]); // SLOAD each struct instead of the whole array before the FOR loop.
        }
        return _data;
    }

    function _getPrizeTier(uint32 _drawId) internal view returns (PrizeTier memory) {
      uint256 cardinality = history.length;
      require(cardinality > 0, "PrizeTierHistory/no-prize-tiers");

      uint256 leftSide = 0;
      uint256 rightSide = cardinality - 1;
      uint32 oldestDrawId = history[leftSide].drawId;
      uint32 newestDrawId = history[rightSide].drawId;

      require(_drawId >= oldestDrawId, "PrizeTierHistory/draw-id-out-of-range");
      if (_drawId >= newestDrawId) return history[rightSide];
      if (_drawId == oldestDrawId) return history[leftSide];

      return _binarySearch(_drawId, leftSide, rightSide, history);
    }

    function _binarySearch(
      uint32 _drawId,
      uint256 leftSide,
      uint256 rightSide,
      PrizeTier[] storage _history
    ) internal view returns (PrizeTier memory) {
        return _history[_binarySearchIndex(_drawId, leftSide, rightSide, _history)];
    }

    function _binarySearchIndex(
      uint32 _drawId,
      uint256 _leftSide,
      uint256 _rightSide,
      PrizeTier[] storage _history
    ) internal view returns (uint256) {
      uint256 index;
      uint256 leftSide = _leftSide;
      uint256 rightSide = _rightSide;
      while (true) {
            uint256 center = leftSide + (rightSide - leftSide) / 2;
            uint32 centerPrizeTierID = _history[center].drawId;

            if (centerPrizeTierID == _drawId) {
                index = center;
                break;
            }

            if (centerPrizeTierID < _drawId) {
                leftSide = center + 1;
            } else if (centerPrizeTierID > _drawId) {
                rightSide = center - 1;
            }

            if (leftSide == rightSide) {
                if (centerPrizeTierID >= _drawId) {
                    index = center - 1;
                    break;
                } else {
                    index = center;
                    break;
                }
            }
        }
        return index;
    }

    function getPrizeTierAtIndex(uint256 index) external override view returns (PrizeTier memory) {
        return history[index];
    }

    function count() external override view returns (uint256) {
        return history.length;
    }
}
