pragma solidity 0.5.17;

import "./SafeMath.sol";

/**
 * @title Logic for Compound's JumpRateModel Contract V2.
 * @author Compound (modified by Dharma Labs, refactored by Arr00)
 * @notice Version 2 modifies Version 1 by enabling updateable parameters.
 */
contract BaseJumpRateModelV2 {
  using SafeMath for uint256;

  event NewInterestParams(
    uint256 baseRatePerBlock,
    uint256 multiplierPerBlock,
    uint256 jumpMultiplierPerBlock,
    uint256 kink
  );

  /**
   * @notice The address of the owner, i.e. the Timelock contract, which can update parameters directly
   */
  address public owner;

  /**
   * @notice The approximate number of blocks per year that is assumed by the interest rate model
   */
  uint256 public constant blocksPerYear = 2102400;

  /**
   * @notice The multiplier of utilization rate that gives the slope of the interest rate
   */
  uint256 public multiplierPerBlock;

  /**
   * @notice The base interest rate which is the y-intercept when utilization rate is 0
   */
  uint256 public baseRatePerBlock;

  /**
   * @notice The multiplierPerBlock after hitting a specified utilization point
   */
  uint256 public jumpMultiplierPerBlock;

  /**
   * @notice The utilization point at which the jump multiplier is applied
   */
  uint256 public kink;

  /**
   * @notice Construct an interest rate model
   * @param baseRatePerYear The approximate target base APR, as a mantissa (scaled by 1e18)
   * @param multiplierPerYear The rate of increase in interest rate wrt utilization (scaled by 1e18)
   * @param jumpMultiplierPerYear The multiplierPerBlock after hitting a specified utilization point
   * @param kink_ The utilization point at which the jump multiplier is applied
   * @param owner_ The address of the owner, i.e. the Timelock contract (which has the ability to update parameters directly)
   */
  constructor(
    uint256 baseRatePerYear,
    uint256 multiplierPerYear,
    uint256 jumpMultiplierPerYear,
    uint256 kink_,
    address owner_
  ) internal {
    owner = owner_;

    updateJumpRateModelInternal(baseRatePerYear, multiplierPerYear, jumpMultiplierPerYear, kink_);
  }

  /**
   * @notice Update the parameters of the interest rate model (only callable by owner, i.e. Timelock)
   * @param baseRatePerYear The approximate target base APR, as a mantissa (scaled by 1e18)
   * @param multiplierPerYear The rate of increase in interest rate wrt utilization (scaled by 1e18)
   * @param jumpMultiplierPerYear The multiplierPerBlock after hitting a specified utilization point
   * @param kink_ The utilization point at which the jump multiplier is applied
   */
  function updateJumpRateModel(
    uint256 baseRatePerYear,
    uint256 multiplierPerYear,
    uint256 jumpMultiplierPerYear,
    uint256 kink_
  ) external {
    require(msg.sender == owner, "only the owner may call this function.");

    updateJumpRateModelInternal(baseRatePerYear, multiplierPerYear, jumpMultiplierPerYear, kink_);
  }

  /**
   * @notice Calculates the utilization rate of the market: `borrows / (cash + borrows - reserves)`
   * @param cash The amount of cash in the market
   * @param borrows The amount of borrows in the market
   * @param reserves The amount of reserves in the market (currently unused)
   * @return The utilization rate as a mantissa between [0, 1e18]
   */
  function utilizationRate(
    uint256 cash,
    uint256 borrows,
    uint256 reserves
  ) public pure returns (uint256) {
    // Utilization rate is 0 when there are no borrows
    if (borrows == 0) {
      return 0;
    }

    return borrows.mul(1e18).div(cash.add(borrows).sub(reserves));
  }

  /**
   * @notice Calculates the current borrow rate per block, with the error code expected by the market
   * @param cash The amount of cash in the market
   * @param borrows The amount of borrows in the market
   * @param reserves The amount of reserves in the market
   * @return The borrow rate percentage per block as a mantissa (scaled by 1e18)
   */
  function getBorrowRateInternal(
    uint256 cash,
    uint256 borrows,
    uint256 reserves
  ) internal view returns (uint256) {
    uint256 util = utilizationRate(cash, borrows, reserves);

    if (util <= kink) {
      return util.mul(multiplierPerBlock).div(1e18).add(baseRatePerBlock);
    } else {
      uint256 normalRate = kink.mul(multiplierPerBlock).div(1e18).add(baseRatePerBlock);
      uint256 excessUtil = util.sub(kink);
      return excessUtil.mul(jumpMultiplierPerBlock).div(1e18).add(normalRate);
    }
  }

  /**
   * @notice Calculates the current supply rate per block
   * @param cash The amount of cash in the market
   * @param borrows The amount of borrows in the market
   * @param reserves The amount of reserves in the market
   * @param reserveFactorMantissa The current reserve factor for the market
   * @return The supply rate percentage per block as a mantissa (scaled by 1e18)
   */
  function getSupplyRate(
    uint256 cash,
    uint256 borrows,
    uint256 reserves,
    uint256 reserveFactorMantissa
  ) public view returns (uint256) {
    uint256 oneMinusReserveFactor = uint256(1e18).sub(reserveFactorMantissa);
    uint256 borrowRate = getBorrowRateInternal(cash, borrows, reserves);
    uint256 rateToPool = borrowRate.mul(oneMinusReserveFactor).div(1e18);
    return utilizationRate(cash, borrows, reserves).mul(rateToPool).div(1e18);
  }

  /**
   * @notice Internal function to update the parameters of the interest rate model
   * @param baseRatePerYear The approximate target base APR, as a mantissa (scaled by 1e18)
   * @param multiplierPerYear The rate of increase in interest rate wrt utilization (scaled by 1e18)
   * @param jumpMultiplierPerYear The multiplierPerBlock after hitting a specified utilization point
   * @param kink_ The utilization point at which the jump multiplier is applied
   */
  function updateJumpRateModelInternal(
    uint256 baseRatePerYear,
    uint256 multiplierPerYear,
    uint256 jumpMultiplierPerYear,
    uint256 kink_
  ) internal {
    baseRatePerBlock = baseRatePerYear.div(blocksPerYear);
    multiplierPerBlock = (multiplierPerYear.mul(1e18)).div(blocksPerYear.mul(kink_));
    jumpMultiplierPerBlock = jumpMultiplierPerYear.div(blocksPerYear);
    kink = kink_;

    emit NewInterestParams(baseRatePerBlock, multiplierPerBlock, jumpMultiplierPerBlock, kink);
  }
}
