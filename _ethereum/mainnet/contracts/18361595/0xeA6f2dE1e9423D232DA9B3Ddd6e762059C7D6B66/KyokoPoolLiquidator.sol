// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.18;

import "./IKyokoPoolLiquidator.sol";
import "./IKyokoPool.sol";
import "./ReserveLogic.sol";
import "./ValidationLogic.sol";
import "./ReserveConfiguration.sol";
import "./WadRayMath.sol";
import "./PercentageMath.sol";
import "./MathUtils.sol";
import "./DataTypes.sol";
import "./Helpers.sol";
import "./Errors.sol";
import "./KyokoPoolStorage.sol";
import "./KyokoPoolStorageExt.sol";

import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./CountersUpgradeable.sol";
import "./SafeCastUpgradeable.sol";
import "./EnumerableSetUpgradeable.sol";
import "./Initializable.sol";
import "./ContextUpgradeable.sol";

contract KyokoPoolLiquidator is
    Initializable,
    IKyokoPoolLiquidator,
    KyokoPoolStorage,
    ContextUpgradeable,
    KyokoPoolStorageExt
{
    using WadRayMath for uint256;
    using PercentageMath for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using ReserveLogic for DataTypes.ReserveData;
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    /**
     * @dev Allows users to liquidate the loans that have expired
     * @param borrowId The id of liquidate borrow target
     */
    function liquidationCall(
        uint256 borrowId,
        uint256 amount
    ) external payable override returns (uint256, string memory) {
        uint256 innerBorrowId = borrowId;
        DataTypes.BorrowInfo storage info = borrowMap[innerBorrowId];
        uint256 reserveId = info.reserveId;
        DataTypes.ReserveData storage reserve = _reserves[reserveId];
        uint256 amountToLiquidation = amount;

        DataTypes.InterestRateMode interestRateMode = info.rateMode;
        uint256 repayAmount = 0;
        if (interestRateMode == DataTypes.InterestRateMode.STABLE) {
            (repayAmount, ) = Helpers.getUserDebtOfAmount(
                info.user,
                reserve,
                info.principal
            );
        } else {
            (, repayAmount) = Helpers.getUserDebtOfAmount(
                info.user,
                reserve,
                info.principal
            );
        }
        address oracle = _addressesProvider.getPriceOracle()[0];
        address nftAddress = info.nft;
        uint256 floor = SafeCastUpgradeable.toUint256(
            IPriceOracle(oracle).getPrice(nftAddress)
        );

        ValidationLogic.validateLiquidationCall(
            reserve,
            info,
            amountToLiquidation,
            repayAmount,
            floor
        );

        reserve.updateState();

        if (interestRateMode == DataTypes.InterestRateMode.STABLE) {
            IStableDebtToken(reserve.stableDebtTokenAddress).burn(
                info.user,
                repayAmount
            );
        } else {
            IVariableDebtToken(reserve.variableDebtTokenAddress).burn(
                info.user,
                repayAmount,
                reserve.variableBorrowIndex
            );
        }

        address kToken = reserve.kTokenAddress;

        reserve.updateInterestRates(
            address(WETH),
            kToken,
            amountToLiquidation,
            0
        );

        IERC20Upgradeable(address(WETH)).safeTransferFrom(
            // _msgSender(),
            address(this),
            kToken,
            amountToLiquidation
        );

        info.status = DataTypes.Status.AUCTION;
        userBorrowIdMap[info.user].remove(innerBorrowId);
        uint256 liquidationDuration = reserve
            .configuration
            .getLiquidationTime();
        // operator is the first bidder
        auctionMap[innerBorrowId] = DataTypes.Auction({
            endTime: block.timestamp + liquidationDuration,
            bidder: payable(msg.sender),
            startTime: block.timestamp,
            borrowId: innerBorrowId,
            amount: amountToLiquidation,
            settled: false
        });

        auctions.add(innerBorrowId);
        uint256 nftID = info.nftId;
        emit LiquidationCall(
            reserveId,
            innerBorrowId,
            _msgSender(),
            nftAddress,
            nftID,
            amountToLiquidation,
            block.timestamp
        );
        return (0, Errors.KPCM_NO_ERRORS);
    }

    /**
     * @dev Allows users bid for a liquidated auction
     * @param borrowId The id of liquidate borrow target
     */
    function bidCall(
        uint256 borrowId,
        uint256 amount
    ) external payable override returns (address, uint256) {
        uint256 amountToBid = amount;
        uint256 innerBorrowId = borrowId;
        DataTypes.BorrowInfo memory info = borrowMap[innerBorrowId];
        uint256 reserveId = info.reserveId;
        DataTypes.ReserveData storage reserve = _reserves[reserveId];
        DataTypes.Auction storage _auction = auctionMap[innerBorrowId];
        reserve.updateState();
        ValidationLogic.validateBidCall(_auction, info.status, amountToBid);

        address payable lastBidder = _auction.bidder;
        address kToken = reserve.kTokenAddress;

        reserve.updateInterestRates(
            address(WETH),
            kToken,
            amountToBid - _auction.amount,
            0
        );
        IERC20Upgradeable(address(WETH)).safeTransferFrom(
            // _msgSender(),
            address(this),
            kToken,
            amountToBid
        );
        address lastUser = address(0);
        uint256 lastAmount = 0;
        if (lastBidder != address(0)) {
            // Refund the last bidder, if applicable
            lastUser = lastBidder;
            lastAmount = _auction.amount;
        }
        uint256 bidDuration = reserve.configuration.getBidTime();
        _auction.amount = amountToBid;
        _auction.endTime += bidDuration;
        _auction.bidder = payable(msg.sender);

        emit BidCall(
            reserveId,
            innerBorrowId,
            msg.sender,
            amountToBid,
            block.timestamp
        );

        return (lastUser, lastAmount);
    }

    /**
     * @dev Allows users to claim the nft that has been auctioned success
     * @param borrowId The id of borrow target
     */
    function claimCall(
        uint256 borrowId
    ) external override returns (uint256, string memory) {
        DataTypes.Auction storage _auction = auctionMap[borrowId];
        DataTypes.BorrowInfo storage info = borrowMap[borrowId];
        uint256 reserveId = info.reserveId;
        DataTypes.ReserveData storage reserve = _reserves[reserveId];
        ValidationLogic.validateClaimCall(info, _auction, _msgSender());

        _auction.settled = true;
        auctions.remove(borrowId);
        info.status = DataTypes.Status.WITHDRAW;
        address kToken = reserve.kTokenAddress;

        IKToken(kToken).transferUnderlyingNFTTo(
            info.nft,
            _msgSender(),
            info.nftId
        );

        emit ClaimCall(reserveId, borrowId, _msgSender(), block.timestamp);
        return (0, Errors.KPCM_NO_ERRORS);
    }

    function claimCall(
        uint256 borrowId,
        address onBehalfOf
    ) external returns (uint256, string memory) {
        DataTypes.Auction storage _auction = auctionMap[borrowId];
        DataTypes.BorrowInfo storage info = borrowMap[borrowId];
        uint256 reserveId = info.reserveId;
        DataTypes.ReserveData storage reserve = _reserves[reserveId];
        ValidationLogic.validateClaimCall(info, _auction, onBehalfOf);

        _auction.settled = true;
        auctions.remove(borrowId);
        info.status = DataTypes.Status.WITHDRAW;
        address kToken = reserve.kTokenAddress;

        IKToken(kToken).transferUnderlyingNFTTo(
            info.nft,
            onBehalfOf,
            info.nftId
        );

        emit ClaimCall(reserveId, borrowId, onBehalfOf, block.timestamp);
        return (0, Errors.KPCM_NO_ERRORS);
    }
}
