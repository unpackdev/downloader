// SPDX-License-Identifier: MITs
pragma solidity 0.8.18;

import "./SafeMathUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ITroveManager.sol";
import "./ICollateralManager.sol";
import "./ITroveDebt.sol";
import "./IActivePool.sol";
import "./IDefaultPool.sol";
import "./IStabilityPool.sol";
import "./ITroveInterestRateStrategy.sol";
import "./IPriceFeed.sol";
import "./WadRayMath.sol";
import "./DataTypes.sol";
import "./Errors.sol";

contract TroveInterestRateStrategy is
    OwnableUpgradeable,
    ITroveInterestRateStrategy
{
    using SafeMathUpgradeable for uint256;
    using WadRayMath for uint256;

    /**
     * @dev this represents the optimal collateral ratio
     * Expressed in ray
     **/
    uint256 public OCR;

    // Base borrow rate when TCR <= CCR. Expressed in ray
    uint256 internal baseBorrowRate;

    // Slope of the interest curve when TCR > CCR and <= OCR.rayToWad(). Expressed in ray
    uint256 internal rateSlope1;

    // Slope of the interest curve when TCR > OCR.rayToWad(). Expressed in ray
    uint256 internal rateSlope2;

    ITroveManager public troveManager;

    ICollateralManager public collateralManager;

    ITroveDebt public troveDebt;

    IActivePool public activePool;

    IDefaultPool public defaultPool;

    IStabilityPool public stabilityPool;

    IPriceFeed public priceFeed;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        uint256 _OCR,
        uint256 _baseBorrowRate,
        uint256 _rateSlope1,
        uint256 _rateSlope2
    ) public initializer {
        __Ownable_init();
        OCR = _OCR;
        baseBorrowRate = _baseBorrowRate;
        rateSlope1 = _rateSlope1;
        rateSlope2 = _rateSlope2;
    }

    function setAddresses(
        address _troveManagerAddress,
        address _collateralManagerAddress,
        address _troveDebtAddress,
        address _activePoolAddress,
        address _defaultPoolAddress,
        address _stabilityPoolAddress,
        address _priceFeedAddress
    ) external onlyOwner {
        _requireIsContract(_troveManagerAddress);
        _requireIsContract(_collateralManagerAddress);
        _requireIsContract(_troveDebtAddress);
        _requireIsContract(_activePoolAddress);
        _requireIsContract(_defaultPoolAddress);
        _requireIsContract(_stabilityPoolAddress);
        _requireIsContract(_priceFeedAddress);

        troveManager = ITroveManager(_troveManagerAddress);
        collateralManager = ICollateralManager(_collateralManagerAddress);
        troveDebt = ITroveDebt(_troveDebtAddress);
        activePool = IActivePool(_activePoolAddress);
        defaultPool = IDefaultPool(_defaultPoolAddress);
        stabilityPool = IStabilityPool(_stabilityPoolAddress);
        priceFeed = IPriceFeed(_priceFeedAddress);
    }

    function getRateSlope1() external view returns (uint256) {
        return rateSlope1;
    }

    function getRateSlope2() external view returns (uint256) {
        return rateSlope2;
    }

    function getBaseBorrowRate() external view override returns (uint256) {
        return baseBorrowRate;
    }

    function getMaxBorrowRate() external view override returns (uint256) {
        return baseBorrowRate.add(rateSlope1).add(rateSlope2);
    }

    function setRateSlope1(uint256 _slope1) external onlyOwner {
        rateSlope1 = _slope1;
    }

    function setRateSlope2(uint256 _slope2) external onlyOwner {
        rateSlope2 = _slope2;
    }

    function setBaseBorrowRate(uint256 _baseRate) external onlyOwner {
        baseBorrowRate = _baseRate;
    }

    function renounceOwnership() public view override onlyOwner {
        revert Errors.OwnershipCannotBeRenounced();
    }

    struct CalcInterestRatesLocalVars {
        uint256 currentBorrowRate;
        uint256 utilizationRate;
        uint256 TCR;
        uint256 CCR;
    }

    /**
     * @dev Calculates the interest rates depending on the trove's state and configurations.
     * @return The liquidity rate, and the variable borrow rate
     **/
    function calculateInterestRates() public view override returns (uint256) {
        CalcInterestRatesLocalVars memory vars;
        vars.TCR = troveManager.getTCR(priceFeed.fetchPrice_view());
        vars.CCR = collateralManager.getCCR();

        vars.currentBorrowRate = 0;

        vars.utilizationRate = vars.CCR.wadDiv(vars.TCR).wadToRay();

        uint256 optimalUtilizationRate = vars.CCR.wadToRay().rayDiv(OCR);
        if (vars.utilizationRate >= WadRayMath.ray()) {
            vars.currentBorrowRate = baseBorrowRate;
        } else {
            if (vars.utilizationRate >= optimalUtilizationRate) {
                vars.currentBorrowRate = baseBorrowRate.add(
                    rateSlope1.rayMul(
                        (vars.TCR.sub(vars.CCR).wadToRay()).rayDiv(
                            OCR.sub(vars.CCR.wadToRay())
                        )
                    )
                );
            } else {
                uint256 remaindUtilizationRateRatio = vars
                    .TCR
                    .wadToRay()
                    .rayDiv(OCR) - WadRayMath.ray();

                vars.currentBorrowRate = baseBorrowRate.add(rateSlope1).add(
                    rateSlope2.rayMul(remaindUtilizationRateRatio)
                );
            }
        }
        uint256 maxRate = baseBorrowRate.add(rateSlope1).add(rateSlope2);
        if (vars.currentBorrowRate > maxRate) {
            return maxRate;
        }
        return vars.currentBorrowRate;
    }

    function _requireIsContract(address _contract) internal view {
        if (_contract.code.length == 0) {
            revert Errors.NotContract();
        }
    }
}
