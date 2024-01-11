// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.9;

import "./InterestRateModel.sol";
import "./AccessControl.sol";

/**
 * @title Minterest's KinkMultiplierModel Contract
 */
contract KinkMultiplierModel is InterestRateModel, AccessControl {
    event NewInitialRatePerBlock(uint256 oldInitialRatePerBlock, uint256 newInitialRatePerBlock);
    event NewInterestRateMultiplierPerBlock(
        uint256 oldInterestRateMultiplierPerBlock,
        uint256 newInterestRateMultiplierPerBlock
    );
    event NewKinkCurveMultiplierPerBlock(
        uint256 oldKinkCurveMultiplierPerBlock,
        uint256 newKinkCurveMultiplierPerBlock
    );
    event NewKinkPoint(uint256 oldKinkPoint, uint256 newKinkPoint);

    /// @dev Value is the Keccak-256 hash of "TIMELOCK"
    bytes32 public constant TIMELOCK = bytes32(0xaefebe170cbaff0af052a32795af0e1b8afff9850f946ad2869be14f35534371);
    /**
     * @notice The approximate number of blocks per year that is assumed by the interest rate model
     */
    uint256 public constant blocksPerYear = 2102400;

    /**
     * @notice The multiplier of utilisation rate that gives the slope of the interest rate
     */
    uint256 public interestRateMultiplierPerBlock;

    /**
     * @notice The initial interest rate which is the y-intercept when utilisation rate is 0
     */
    uint256 public initialRatePerBlock;

    /**
     * @notice The interestRateMultiplierPerBlock after hitting a specified utilisation point
     */
    uint256 public kinkCurveMultiplierPerBlock;

    /**
     * @notice The utilisation point at which the kink curve multiplier is applied
     */
    uint256 public kinkPoint;

    /**
     * @notice Construct an interest rate model
     * @param initialRatePerYear The approximate target initial APR, as a mantissa (scaled by 1e18)
     * @param interestRateMultiplierPerYear Interest rate to utilisation rate increase ratio (scaled by 1e18)
     * @param kinkCurveMultiplierPerYear The multiplier per year after hitting a kink point
     * @param kinkPoint_ The utilisation point at which the kink curve multiplier is applied
     * @param admin_ The address of the Admin
     */
    constructor(
        uint256 initialRatePerYear,
        uint256 interestRateMultiplierPerYear,
        uint256 kinkCurveMultiplierPerYear,
        uint256 kinkPoint_,
        address admin_
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
        _grantRole(TIMELOCK, admin_);
        _updateInitialRatePerBlock(initialRatePerYear);
        _updateInterestRateMultiplierPerBlock(interestRateMultiplierPerYear);
        _updateKinkCurveMultiplierPerBlock(kinkCurveMultiplierPerYear);
        _updateKinkPoint(kinkPoint_);
    }

    /**
     * @notice Calculates the current borrow rate per block, with the error code expected by the market
     * @param cash The amount of cash in the market
     * @param borrows The amount of borrows in the market
     * @param protocolInterest The amount of protocol interest in the market
     * @return The borrow rate percentage per block as a mantissa (scaled by 1e18)
     */
    function getBorrowRate(
        uint256 cash,
        uint256 borrows,
        uint256 protocolInterest
    ) public view override returns (uint256) {
        uint256 util = utilisationRate(cash, borrows, protocolInterest);
        if (util <= kinkPoint) {
            return (util * interestRateMultiplierPerBlock) / 1e18 + initialRatePerBlock;
        } else {
            uint256 normalRate = (kinkPoint * interestRateMultiplierPerBlock) / 1e18 + initialRatePerBlock;
            uint256 excessUtil = util - kinkPoint;
            return (excessUtil * kinkCurveMultiplierPerBlock) / 1e18 + normalRate;
        }
    }

    /**
     * @notice Calculates the current supply rate per block
     * @param cash The amount of cash in the market
     * @param borrows The amount of borrows in the market
     * @param protocolInterest The amount of protocol interest in the market
     * @param protocolInterestFactorMantissa The current protocol interest factor for the market
     * @return The supply rate percentage per block as a mantissa (scaled by 1e18)
     */
    function getSupplyRate(
        uint256 cash,
        uint256 borrows,
        uint256 protocolInterest,
        uint256 protocolInterestFactorMantissa
    ) external view override returns (uint256) {
        uint256 oneMinusProtocolInterestFactor = uint256(1e18) - protocolInterestFactorMantissa;
        uint256 borrowRate = getBorrowRate(cash, borrows, protocolInterest);
        uint256 rateToPool = (borrowRate * oneMinusProtocolInterestFactor) / 1e18;
        return (utilisationRate(cash, borrows, protocolInterest) * rateToPool) / 1e18;
    }

    /**
     * @notice Update the initialRatePerBlock of the interest rate model (only callable by admin, i.e. Timelock)
     * @param initialRatePerYear The approximate target initial APR, as a mantissa (scaled by 1e18)
     */
    function updateInitialRatePerBlock(uint256 initialRatePerYear) external onlyRole(TIMELOCK) {
        _updateInitialRatePerBlock(initialRatePerYear);
    }

    function _updateInitialRatePerBlock(uint256 initialRatePerYear) internal {
        uint256 oldInitialRatePerBlock = initialRatePerBlock;
        initialRatePerBlock = initialRatePerYear / blocksPerYear;

        emit NewInitialRatePerBlock(oldInitialRatePerBlock, initialRatePerBlock);
    }

    /**
     * @notice Update the interestRateMultiplierPerBlock of the interest rate model
     *     (only callable by admin, i.e. Timelock)
     * @param interestRateMultiplierPerYear Interest rate to utilisation rate increase ratio (scaled by 1e18)
     */
    function updateInterestRateMultiplierPerBlock(uint256 interestRateMultiplierPerYear) external onlyRole(TIMELOCK) {
        _updateInterestRateMultiplierPerBlock(interestRateMultiplierPerYear);
    }

    function _updateInterestRateMultiplierPerBlock(uint256 interestRateMultiplierPerYear) internal {
        uint256 oldInterestRateMultiplierPerBlock = interestRateMultiplierPerBlock;
        interestRateMultiplierPerBlock = interestRateMultiplierPerYear / blocksPerYear;

        emit NewInterestRateMultiplierPerBlock(oldInterestRateMultiplierPerBlock, interestRateMultiplierPerBlock);
    }

    /**
     * @notice Update the kinkCurveMultiplierPerBlock of the interest rate model (only callable by admin, i.e. Timelock)
     * @param kinkCurveMultiplierPerYear The multiplier per year after hitting a kink point
     */
    function updateKinkCurveMultiplierPerBlock(uint256 kinkCurveMultiplierPerYear) external onlyRole(TIMELOCK) {
        _updateKinkCurveMultiplierPerBlock(kinkCurveMultiplierPerYear);
    }

    function _updateKinkCurveMultiplierPerBlock(uint256 kinkCurveMultiplierPerYear) internal {
        uint256 oldKinkCurveMultiplierPerBlock = kinkCurveMultiplierPerBlock;
        kinkCurveMultiplierPerBlock = kinkCurveMultiplierPerYear / blocksPerYear;

        emit NewKinkCurveMultiplierPerBlock(oldKinkCurveMultiplierPerBlock, kinkCurveMultiplierPerBlock);
    }

    /**
     * @notice Update the kinkPoint of the interest rate model (only callable by admin, i.e. Timelock)
     * @param kinkPoint_ The utilisation point at which the kink curve multiplier is applied
     */
    function updateKinkPoint(uint256 kinkPoint_) external onlyRole(TIMELOCK) {
        _updateKinkPoint(kinkPoint_);
    }

    function _updateKinkPoint(uint256 kinkPoint_) internal {
        uint256 oldKinkPoint = kinkPoint;
        kinkPoint = kinkPoint_;

        emit NewKinkPoint(oldKinkPoint, kinkPoint);
    }

    /**
     * @notice Calculates the utilisation rate of the market: `borrows / (cash + borrows - protocol interest)`
     * @param cash The amount of cash in the market
     * @param borrows The amount of borrows in the market
     * @param protocolInterest The amount of protocol interest in the market
     * @return The utilisation rate as a mantissa between [0, 1e18]
     */
    function utilisationRate(
        uint256 cash,
        uint256 borrows,
        uint256 protocolInterest
    ) public pure returns (uint256) {
        // Utilisation rate is 0 when there are no borrows
        if (borrows == 0) {
            return 0;
        }

        return (borrows * 1e18) / (cash + borrows - protocolInterest);
    }

    /// @dev Returns true if this contract implements the interface defined by `interfaceId`
    function supportsInterface(bytes4 interfaceId) public pure override(AccessControl, IERC165) returns (bool) {
        return interfaceId == type(InterestRateModel).interfaceId;
    }
}
