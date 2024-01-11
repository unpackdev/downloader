// SPDX-License-Identifier: MIT

// =================================================================================================================
//  _|_|_|    _|_|_|_|  _|    _|    _|_|_|      _|_|_|_|  _|                                                       |
//  _|    _|  _|        _|    _|  _|            _|            _|_|_|      _|_|_|  _|_|_|      _|_|_|    _|_|       |
//  _|    _|  _|_|_|    _|    _|    _|_|        _|_|_|    _|  _|    _|  _|    _|  _|    _|  _|        _|_|_|_|     |
//  _|    _|  _|        _|    _|        _|      _|        _|  _|    _|  _|    _|  _|    _|  _|        _|           |
//  _|_|_|    _|_|_|_|    _|_|    _|_|_|        _|        _|  _|    _|    _|_|_|  _|    _|    _|_|_|    _|_|_|     |
// =================================================================================================================
// ============================= Oracle =============================
// ==================================================================
// DEUS Finance: https://github.com/DeusFinance

// Primary Author(s)
// Sina: https://github.com/spsina
// Vahid: https://github.com/vahid-dev

import "./IMuonV02.sol";

interface IDEIPool {
    struct RecollateralizeDeiParams {
        uint256 collateralAmount;
        uint256 poolCollateralPrice;
        uint256[] collateralPrice;
        uint256 deusPrice;
        uint256 expireBlock;
        bytes[] sigs;
    }

    struct RedeemPosition {
        uint256 amount;
        uint256 timestamp;
    }

    /* ========== PUBLIC VIEWS ========== */

    function collatDollarBalance(uint256 collateralPrice)
        external
        view
        returns (uint256 balance);

    function positionsLength(address user)
        external
        view
        returns (uint256 length);

    function getAllPositions(address user)
        external
        view
        returns (RedeemPosition[] memory positinos);

    function getUnRedeemedPositions(address user)
        external
        view
        returns (RedeemPosition[] memory positions);

    function mint1t1DEI(uint256 collateralAmount)
        external
        returns (uint256 deiAmount);

    function mintAlgorithmicDEI(
        uint256 deusAmount,
        uint256 deusPrice,
        uint256 expireBlock,
        bytes[] calldata sigs
    ) external returns (uint256 deiAmount);

    function mintFractionalDEI(
        uint256 collateralAmount,
        uint256 deusAmount,
        uint256 deusPrice,
        uint256 expireBlock,
        bytes[] calldata sigs
    ) external returns (uint256 mintAmount);

    function redeem1t1DEI(uint256 deiAmount) external;

    function redeemFractionalDEI(uint256 deiAmount) external;

    function redeemAlgorithmicDEI(uint256 deiAmount) external;

    function collectCollateral() external;

    function collectDeus(
        uint256 price,
        bytes calldata _reqId,
        SchnorrSign[] calldata sigs
    ) external;

    function RecollateralizeDei(RecollateralizeDeiParams memory inputs)
        external;

    function buyBackDeus(
        uint256 deusAmount,
        uint256[] memory collateralPrice,
        uint256 deusPrice,
        uint256 expireBlock,
        bytes[] calldata sigs
    ) external;

    /* ========== RESTRICTED FUNCTIONS ========== */
    function collectDaoShare(uint256 amount, address to) external;

    function emergencyWithdrawERC20(
        address token,
        uint256 amount,
        address to
    ) external;

    function toggleMinting() external;

    function toggleRedeeming() external;

    function toggleRecollateralize() external;

    function toggleBuyBack() external;

    function setPoolParameters(
        uint256 poolCeiling_,
        uint256 bonusRate_,
        uint256 collateralRedemptionDelay_,
        uint256 deusRedemptionDelay_,
        uint256 mintingFee_,
        uint256 redemptionFee_,
        uint256 buybackFee_,
        uint256 recollatFee_,
        address muon_,
        uint32 appId_,
        uint256 minimumRequiredSignatures_
    ) external;

    /* ========== EVENTS ========== */

    event PoolParametersSet(
        uint256 poolCeiling,
        uint256 bonusRate,
        uint256 collateralRedemptionDelay,
        uint256 deusRedemptionDelay,
        uint256 mintingFee,
        uint256 redemptionFee,
        uint256 buybackFee,
        uint256 recollatFee,
        address muon,
        uint32 appId,
        uint256 minimumRequiredSignatures
    );
    event daoShareCollected(uint256 daoShare, address to);
    event MintingToggled(bool toggled);
    event RedeemingToggled(bool toggled);
    event RecollateralizeToggled(bool toggled);
    event BuybackToggled(bool toggled);
}
