// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IStrategy.sol";

import "./IDutchAuctionFacet.sol";

import "./FullMath.sol";

contract DutchAuctionFacet is IDutchAuctionFacet {
    error Forbidden();
    error InvalidState();

    uint256 public constant Q96 = 2 ** 96;
    bytes32 public constant STORAGE_POSITION = keccak256("mellow.contracts.auction.storage");

    struct DutchAuctionStorage {
        uint32 duration;
        uint256 startCoefficientX96;
        uint256 endCoefficientX96;
        uint256 startTimestamp;
    }

    function _getDutchAuctionCoefficient() internal view returns (uint256 coefficientX96) {
        Storage memory ds = _contractStorage();
        uint256 timestamp = block.timestamp;
        if (timestamp >= ds.startTimestamp + ds.duration) {
            coefficientX96 = ds.endCoefficientX96;
        } else {
            coefficientX96 =
                FullMath.mulDiv(
                    ds.duration + ds.startTimestamp - timestamp,
                    ds.startCoefficientX96 - ds.endCoefficientX96,
                    ds.duration
                ) +
                ds.endCoefficientX96;
        }
    }

    function _contractStorage() internal pure returns (IDutchAuctionFacet.Storage storage ds) {
        bytes32 position = STORAGE_POSITION;

        assembly {
            ds.slot := position
        }
    }

    function updateAuctionParams(
        uint256 startCoefficientX96,
        uint256 endCoefficientX96,
        uint32 duration,
        address strategy
    ) external {
        IPermissionsFacet(address(this)).requirePermission(msg.sender, address(this), msg.sig);
        _contractStorage().duration = duration;
        _contractStorage().startCoefficientX96 = startCoefficientX96;
        _contractStorage().endCoefficientX96 = endCoefficientX96;
        _contractStorage().strategy = strategy;
    }

    function startAuction() external {
        if (!IStrategy(_contractStorage().strategy).canStartAuction()) revert InvalidState();
        if (_contractStorage().startTimestamp != 0) revert InvalidState();
        _contractStorage().startTimestamp = block.timestamp;
    }

    function stopAuction() external {
        if (!IStrategy(_contractStorage().strategy).canStopAuction()) revert InvalidState();
        if (_contractStorage().startTimestamp == 0) revert InvalidState();
        _contractStorage().startTimestamp = 0;
    }

    function checkTvlAfterRebalance(uint256 tvlBefore, uint256 tvlAfter) external view returns (bool) {
        uint256 coefficientX96 = _getDutchAuctionCoefficient();
        uint256 minTvl = FullMath.mulDiv(tvlBefore, coefficientX96, Q96);
        return minTvl <= tvlAfter;
    }

    function auctionParams()
        external
        pure
        returns (
            uint256 startCoefficientX96,
            uint256 endCoefficientX96,
            uint32 duration,
            uint256 startTimestamp,
            address strategy
        )
    {
        Storage memory ds = _contractStorage();
        startCoefficientX96 = ds.startCoefficientX96;
        endCoefficientX96 = ds.endCoefficientX96;
        duration = ds.duration;
        startTimestamp = ds.startTimestamp;
        strategy = ds.strategy;
    }

    function finishAuction() external {
        if (msg.sender != address(this)) revert Forbidden();
        if (_contractStorage().startTimestamp == 0) revert InvalidState();
        _contractStorage().startTimestamp = 0;
    }

    function dutchAuctionInitialized() external view returns (bool) {
        return _contractStorage().duration != 0;
    }

    function dutchAuctionSelectors() external pure override returns (bytes4[] memory selectors_) {
        selectors_ = new bytes4[](8);
        selectors_[0] = DutchAuctionFacet.dutchAuctionInitialized.selector;
        selectors_[1] = DutchAuctionFacet.dutchAuctionSelectors.selector;
        selectors_[2] = DutchAuctionFacet.checkTvlAfterRebalance.selector;
        selectors_[3] = DutchAuctionFacet.updateAuctionParams.selector;
        selectors_[4] = DutchAuctionFacet.auctionParams.selector;
        selectors_[5] = DutchAuctionFacet.finishAuction.selector;
        selectors_[6] = DutchAuctionFacet.startAuction.selector;
        selectors_[7] = DutchAuctionFacet.stopAuction.selector;
    }
}
