// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;
pragma experimental ABIEncoderV2;

import "./Initializable.sol";
import "./TroveManager.sol";
import "./ISortedTroves.sol";

/*  Helper contract for grabbing Trove data for the front end. Not part of the core ERD system. */
contract MultiTroveGetter is Initializable {
    struct CombinedTroveData {
        address owner;
        uint256 debt;
        address[] collaterals;
        uint256[] colls;
        uint256[] shares;
        uint256[] stakes;
        uint256[] snapshotColls;
        uint256[] snapshotUSDEDebts;
    }

    TroveManager public troveManager; // XXX Troves missing from ITroveManager?
    ISortedTroves public sortedTroves;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        TroveManager _troveManager,
        ISortedTroves _sortedTroves
    ) public initializer {
        troveManager = _troveManager;
        sortedTroves = _sortedTroves;
    }

    function getMultipleSortedTroves(
        int256 _startIdx,
        uint256 _count
    ) external view returns (CombinedTroveData[] memory _troves) {
        uint256 startIdx;
        bool descend;

        if (_startIdx >= 0) {
            startIdx = uint256(_startIdx);
            descend = true;
        } else {
            startIdx = uint256(-(_startIdx + 1));
            descend = false;
        }

        uint256 sortedTrovesSize = sortedTroves.getSize();

        if (startIdx >= sortedTrovesSize) {
            _troves = new CombinedTroveData[](0);
        } else {
            uint256 maxCount = sortedTrovesSize - startIdx;

            if (_count > maxCount) {
                _count = maxCount;
            }

            if (descend) {
                _troves = _getMultipleSortedTrovesFromHead(startIdx, _count);
            } else {
                _troves = _getMultipleSortedTrovesFromTail(startIdx, _count);
            }
        }
    }

    function _getMultipleSortedTrovesFromHead(
        uint256 _startIdx,
        uint256 _count
    ) internal view returns (CombinedTroveData[] memory _troves) {
        address currentTroveowner = sortedTroves.getFirst();
        uint256 idx = 0;
        for (; idx < _startIdx; ) {
            currentTroveowner = sortedTroves.getNext(currentTroveowner);
            unchecked {
                ++idx;
            }
        }

        _troves = new CombinedTroveData[](_count);
        idx = 0;
        for (; idx < _count; ) {
            _troves[idx] = _getCombinedTroveData(currentTroveowner);

            currentTroveowner = sortedTroves.getNext(currentTroveowner);
            unchecked {
                ++idx;
            }
        }
    }

    function _getMultipleSortedTrovesFromTail(
        uint256 _startIdx,
        uint256 _count
    ) internal view returns (CombinedTroveData[] memory _troves) {
        address currentTroveowner = sortedTroves.getLast();
        uint256 idx = 0;
        for (; idx < _startIdx; ) {
            currentTroveowner = sortedTroves.getPrev(currentTroveowner);
            unchecked {
                ++idx;
            }
        }

        _troves = new CombinedTroveData[](_count);
        idx = 0;
        for (; idx < _count; ) {
            _troves[idx] = _getCombinedTroveData(currentTroveowner);

            currentTroveowner = sortedTroves.getPrev(currentTroveowner);
            unchecked {
                ++idx;
            }
        }
    }

    function _getCombinedTroveData(
        address _troveOwner
    ) internal view returns (CombinedTroveData memory data) {
        data.owner = _troveOwner;
        data.debt = troveManager.getTroveDebt(data.owner);
        (data.colls, data.shares, data.collaterals) = troveManager
            .getTroveColls(data.owner);
        (data.stakes, , ) = troveManager.getTroveStakes(data.owner);
        data.snapshotColls = new uint256[](data.collaterals.length);
        data.snapshotUSDEDebts = new uint256[](data.collaterals.length);
        uint256 collsLen = data.collaterals.length;
        uint256 i = 0;
        for (; i < collsLen; ) {
            address collateral = data.collaterals[i];
            data.snapshotColls[i] = troveManager.getRewardSnapshotColl(
                data.owner,
                collateral
            );
            data.snapshotUSDEDebts[i] = troveManager.getRewardSnapshotUSDE(
                data.owner,
                collateral
            );
            unchecked {
                ++i;
            }
        }
    }
}
