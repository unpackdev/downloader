// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IERC1155Upgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";

import "./TrancheBondStorage.sol";
import "./WaterCommonStorage.sol";
import "./WaterTowerStorage.sol";
import "./EIP2535Initializable.sol";
import "./IrrigationAccessControl.sol";
import "./FullMath.sol";
import "./Constants.sol";
import "./PodTransferHelper.sol";

import "./IPodsOracleUpgradeable.sol";
import "./IERC1155WhitelistUpgradeable.sol";
import "./IBeanstalkPrice.sol";

/// @title  TrancheBond Contract
/// @notice Allows users deposit underlying assets like pods,
///         create tranche and receive underlying assets with tranche
/// @dev    users receive 3 tranche nfts(ERC1155) after deposit underlying assets.
///         tranche A and Tranche B nft holders can list owned nfts on our auction market.
///         users can set maturity date when creating tranche, and after maturity date, can receive underlying assets with tranche

contract TrancheBondUpgradeable is
    EIP2535Initializable,
    IrrigationAccessControl,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable
{
    using TrancheBondStorage for TrancheBondStorage.Layout;
    using WaterTowerStorage for WaterTowerStorage.Layout;

    uint256 internal constant FMV_DENOMINATOR = 100;
    uint256 internal constant MINIMUM_FMV = 1000;
    uint256 internal constant MINIMUM_WATER = 32 * 1e18;
    // Offset(%) for each tranche
    uint256 internal constant OFFSET_A = 0;
    uint256 internal constant OFFSET_B = 20;
    uint256 internal constant OFFSET_Z = 50;
    // FMV(%) for each tranche
    uint256 internal constant FMV_A = 20;
    uint256 internal constant FMV_B = 30;
    uint256 internal constant FMV_Z = 50;
    // 3 tranches like A, B, and Z
    uint256 internal constant TRANCHE_COUNT = 3;

    /// @dev Events
    event CreateTranche(
        uint depositIndex,
        address user,
        uint periodId,
        uint[] depositIndexes,
        uint[] amounts,
        uint[] fmvs
    );
    event ReceivePodsWithTranche(uint trancheId, address user, uint[] podIndexes, uint totalPods);
    event SetMaturityPeriods(uint48[] periods);

    /// @dev Errors
    // errors for tranche pods
    error InvalidPods();
    error NotTranchePods();
    error InsufficientPods();

    // errors for general tranche
    error NotOwnerOfTranche();
    error NotMatureTranche();
    error NotSortedPlots();

    // errors for farmer's market rule
    error NotEligible();

    /// @notice Create tranches by depositing group of pods
    /// @dev See transferPlot function in https://github.com/BeanstalkFarms/Beanstalk/blob/master/protocol/contracts/farm/facets/MarketplaceFacet/MarketplaceFacet.sol
    /// @param indexes Index array of deposited pods
    /// @param starts Array of start number for deposited pods
    /// @param ends Array of end number for deposited pods
    /// @param periodId Maturity Period id

    function createTranchesWithPods(
        uint256[] calldata indexes,
        uint256[] calldata starts,
        uint256[] calldata ends,
        uint8 periodId
    ) external whenNotPaused onlyWaterHolder nonReentrant {
        if (indexes.length != starts.length || indexes.length != ends.length) revert InvalidPods();
        uint256[] memory podIndexes = new uint256[](indexes.length);
        uint256[] memory amounts = new uint256[](indexes.length);
        uint256[] memory fmvs = new uint256[](indexes.length);

        /// @dev sum of FMVs for all deposited plots
        uint256 totalFMV;
        uint256 totalPods;
        // calculate directly price with 6 decimals from beanstalk
        uint256 beanPrice = IBeanstalkPrice(Constants.BEANSTALK_PRICE).price().price;
        for (uint256 i; i < indexes.length; ) {
            uint256[] memory _indexes = indexes;
            uint256 _index = _indexes[i];
            uint256 _start = starts[i];
            uint256 _end = ends[i];
            /// should input plots sorted by index
            if (i >= 1 && _index <= _indexes[i - 1]) revert NotSortedPlots();
            WaterCommonStorage.layout().beanstalk.transferPlot(
                msg.sender,
                address(this),
                _index,
                _start,
                _end
            );
            /// checked inside of transferPlot function
            uint256 amount;
            uint256 id;
            unchecked {
                id = _index + _start;
                podIndexes[i] = id;
                amount = _end - _start;
                amounts[i] = amount;
            }
            totalPods += amount;
            /// @dev we calculate fmv in usd, decimals is 6 and it is same as bean price
            uint256 _fmvInPlot = (IPodsOracleUpgradeable(address(this)).latestPriceOfPods(
                id,
                amount
            ) * beanPrice) / Constants.D18;
            fmvs[i] = _fmvInPlot;
            totalFMV += _fmvInPlot;
            unchecked {
                ++i;
            }
        }
        if (totalFMV < MINIMUM_FMV) revert InvalidPods();
        uint256 curDepositCount = TrancheBondStorage.layout().curDepositCount + 1;
        /// Register deposited plot
        TrancheBondStorage.layout().depositedPods[curDepositCount].podIndexes = podIndexes;
        TrancheBondStorage.layout().depositedPods[curDepositCount].amounts = amounts;
        TrancheBondStorage.layout().depositedPods[curDepositCount].fmvs = fmvs;

        /// Create underlying asset meta data
        TrancheBondStorage.layout().underlyingAssets[curDepositCount] = UnderlyingAssetMetadata({
            contractAddress: Constants.ZERO,
            assetType: UnderlyingAssetType.PODS,
            maturityDate: uint48(block.timestamp) + TrancheBondStorage.layout().periods[periodId],
            totalDeposited: totalPods,
            totalFMV: totalFMV
        });

        /// Create tranche A, B, Z
        _createTranchesFromDeposit(curDepositCount, totalFMV, msg.sender);
        TrancheBondStorage.layout().curDepositCount = curDepositCount;
        emit CreateTranche(curDepositCount, msg.sender, periodId, podIndexes, amounts, fmvs);
    }

    /// @dev receive pods with tranches after maturity date is over
    function receivePodsForTranche(
        uint256 trancheId
    ) external whenNotPaused onlyWaterHolder nonReentrant {
        TrancheBondStorage.Layout storage tancheBondStorage = TrancheBondStorage.layout();
        (uint256 depositId, uint8 trancheLevel) = getTrancheInfo(trancheId);
        DepositPods memory depositPlots = tancheBondStorage.depositedPods[depositId];
        UnderlyingAssetMetadata memory underlyingAsset = TrancheBondStorage
            .layout()
            .underlyingAssets[depositId];
        if (underlyingAsset.assetType != UnderlyingAssetType.PODS) revert NotTranchePods();
        if (block.timestamp < underlyingAsset.maturityDate) revert NotMatureTranche();

        uint256 claimedFMV = tancheBondStorage.tranches[trancheId].claimedFMV;
        uint256 offsetFMV = _offsetFMVForTranche(
            trancheLevel,
            underlyingAsset.totalFMV,
            claimedFMV
        );

        uint256 fmv = IERC1155Upgradeable(address(this)).balanceOf(msg.sender, trancheId);
        if (fmv < MINIMUM_FMV) revert InsufficientPods();

        uint256 startIndex;
        uint256 startOffset;
        uint256[] memory receivePodIndexes = new uint256[](depositPlots.podIndexes.length);
        uint256 totalPods;

        for (uint256 i; i < depositPlots.podIndexes.length; ) {
            if (fmv == 0) break;
            DepositPods memory _depositPlots = depositPlots;
            uint256 plotFMV = _depositPlots.fmvs[i];
            uint256 _fmv = fmv;
            uint256 _level = trancheLevel;
            /// if plot for the tranche is placed in this range
            uint256 _offsetFMV = offsetFMV;
            if (plotFMV >= _offsetFMV) {
                uint256 originalPodIndex = _depositPlots.podIndexes[i];
                uint128[6] memory _startIndexAndOffsets = _depositPlots.startIndexAndOffsets;
                (
                    uint256 offset,
                    uint256 start,
                    uint256 amount,
                    uint256 reserveFMV
                ) = PodTransferHelper.getPlotWithOffset(
                        i,
                        _depositPlots.amounts[i],
                        plotFMV,
                        _offsetFMV,
                        _fmv,
                        _level,
                        _startIndexAndOffsets
                    );
                unchecked {
                    WaterCommonStorage.layout().beanstalk.transferPlot(
                        address(this),
                        msg.sender,
                        originalPodIndex + offset,
                        start,
                        amount + start
                    );
                    receivePodIndexes[i] = originalPodIndex + offset + start;
                    // absolute offset from orignal pod index of podline
                    startOffset = offset + start + amount;
                }
                startIndex = i;
                totalPods += amount;
                _fmv = reserveFMV;
                // offset is always 0 from next podline
                _offsetFMV = 0;
            } else {
                _offsetFMV -= plotFMV;
            }
            offsetFMV = _offsetFMV;
            fmv = _fmv;
            unchecked {
                i++;
            }
        }
        // update startIndex and startOffset for current tranche pods
        tancheBondStorage.depositedPods[depositId].startIndexAndOffsets[trancheLevel] = uint128(
            startIndex
        );
        tancheBondStorage.depositedPods[depositId].startIndexAndOffsets[
            trancheLevel + TRANCHE_COUNT
        ] = uint128(startOffset);
        {
            uint256 _trancheId = trancheId;
            tancheBondStorage.tranches[_trancheId].claimedFMV = claimedFMV + fmv;
            IERC1155BurnableUpgradeable(address(this)).burn(msg.sender, _trancheId, fmv);
            emit ReceivePodsWithTranche(_trancheId, msg.sender, receivePodIndexes, totalPods);
        }
    }

    function _createTranchesFromDeposit(
        uint256 depositId,
        uint256 totalFMVInUSD,
        address owner
    ) internal {
        uint256[TRANCHE_COUNT] memory numeratorFMV = [FMV_A, FMV_B, FMV_Z];
        uint256 trancheAId = (depositId << 2) + 1;
        for (uint256 i; i < TRANCHE_COUNT; ) {
            uint256 trancheId = trancheAId + i;
            uint256 fmv = (totalFMVInUSD * numeratorFMV[i]) / FMV_DENOMINATOR;
            TrancheBondStorage.layout().tranches[trancheId].fmv = fmv;
            /// mint tranche nft with trancheId and totalSupply fmv
            IERC1155WhitelistUpgradeable(address(this)).mint(owner, trancheId, fmv, "");
            unchecked {
                ++i;
            }
        }
    }

    /// @dev get functioins
    function getTranchePods(
        uint256 trancheId
    )
        public
        view
        returns (
            TrancheMetadata memory tranche,
            DepositPods memory depositPods,
            UnderlyingAssetMetadata memory underlyingAsset
        )
    {
        uint256 depositId = trancheId >> 2;
        tranche = TrancheBondStorage.layout().tranches[trancheId];
        underlyingAsset = TrancheBondStorage.layout().underlyingAssets[depositId];
        depositPods = TrancheBondStorage.layout().depositedPods[depositId];
    }

    /// @notice return offset and pods to calculate how much pods users can receive
    /// @param trancheId tranche nft id
    /// @param user user address
    /// @return starts start offset of total pods
    /// @return podAmounts pods amount available for the user
    function getPlotsForUser(
        uint256 trancheId,
        address user
    ) external view returns (uint256[] memory starts, uint256[] memory podAmounts) {
        uint256 claimedFMV = TrancheBondStorage.layout().tranches[trancheId].claimedFMV;
        uint256 userFMV = IERC1155Upgradeable(address(this)).balanceOf(user, trancheId);
        (starts, podAmounts) = _plotsForTranche(trancheId, userFMV, claimedFMV);
    }

    function getPlotsForTranche(
        uint256 trancheId
    ) external view returns (uint256[] memory starts, uint256[] memory podAmounts) {
        uint256 trancheFMV = TrancheBondStorage.layout().tranches[trancheId].fmv;
        uint256 claimedFMV = TrancheBondStorage.layout().tranches[trancheId].claimedFMV;
        return _plotsForTranche(trancheId, trancheFMV, claimedFMV);
    }

    function _offsetFMVForTranche(
        uint8 trancheLevel,
        uint256 totalFMV,
        uint256 claimedFMV
    ) internal pure returns (uint256 offsetFMV) {
        uint256[TRANCHE_COUNT] memory offsetFMVs = [OFFSET_A, OFFSET_B, OFFSET_Z];
        offsetFMV = (offsetFMVs[trancheLevel] * totalFMV) / FMV_DENOMINATOR + claimedFMV;
    }

    /// @notice return start pod indexes and pod amounts to calculate how much pods users can receive
    /// @param trancheId tranche nft id
    /// @return starts start ids in podlines
    /// @return podAmounts pods in podlines

    function _plotsForTranche(
        uint256 trancheId,
        uint256 userFMV,
        uint256 claimedFMV
    ) internal view returns (uint256[] memory starts, uint256[] memory podAmounts) {
        (, uint8 trancheLevel) = getTrancheInfo(trancheId);
        (
            ,
            DepositPods memory depositPlots,
            UnderlyingAssetMetadata memory underlyingAsset
        ) = getTranchePods(trancheId);
        ///@dev plot for tranche is correspond to [offsetFMV, offsetFMV + userFMV]
        uint256 offsetFMV = _offsetFMVForTranche(
            trancheLevel,
            underlyingAsset.totalFMV,
            claimedFMV
        );
        uint256 fmv = userFMV;
        uint256 podlineCount = depositPlots.podIndexes.length;
        starts = new uint256[](podlineCount);
        podAmounts = new uint256[](podlineCount);
        for (uint256 i; i < podlineCount; ) {
            if (fmv == 0) break;
            uint256 plotFMV = depositPlots.fmvs[i];
            /// if plot for the tranche is placed in this range
            if (plotFMV >= offsetFMV) {
                (uint256 start, uint256 amount, uint256 reserveFMV) = PodTransferHelper
                    .getPlotSplittedByFMV(depositPlots.amounts[i], plotFMV, offsetFMV, fmv);
                starts[i] = start;
                podAmounts[i] = amount;
                fmv = reserveFMV;
                offsetFMV = 0;
            } else {
                offsetFMV -= plotFMV;
            }
            unchecked {
                i++;
            }
        }
    }

    /// @dev deposit Id
    /// @param trancheId tranche Id
    /// @return depositId deposit Id
    /// @return trancheLevel tranche level number
    function getTrancheInfo(
        uint256 trancheId
    ) internal pure returns (uint256 depositId, uint8 trancheLevel) {
        return (trancheId >> 2, uint8(trancheId & 3) - 1);
    }

    function setMaturityPeriods(uint48[] calldata periods) external onlyAdminRole {
        TrancheBondStorage.layout().periods = periods;
        emit SetMaturityPeriods(periods);
    }

    /// @dev modifiers
    modifier onlyWaterHolder() {
        if (WaterTowerStorage.userInfo(msg.sender).amount < MINIMUM_WATER) revert NotEligible();
        _;
    }
}
