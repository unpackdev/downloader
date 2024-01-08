// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./SafeERC20.sol";

import "./AaveInterfaces.sol";
import "./ContinuousRewardToken.sol";

/**
 * @title AaveRewardToken contract
 * @notice ERC20 token which wraps underlying (eg USDC) into CB-CY-aUSDC, rewards going to delegatee
 * @dev Initially set to only get Interest Rewards. Can then register potential AAVE Liquidity mining Contract.
 */
contract AaveRewardToken is ContinuousRewardToken {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  // Used to convert between WAD (1e18) and RAY (1e27), based on 
  // https://github.com/aave/protocol-v2/blob/1.0.1/contracts/protocol/libraries/math/WadRayMath.sol
  uint256 internal constant WAD_RAY_RATIO = 1e9;
  // Code used to register the integrator originating the operation, for potential rewards.
  // 0 if the action is executed directly by the user, without any middle-man
  // https://github.com/aave/protocol-v2/blob/1.0.1/contracts/interfaces/ILendingPool.sol#L170
  uint16 internal constant REFERRAL_CODE = 0;
  uint256 internal constant REWARD_RATE_DECIMAL_PRECISION = 1e18;

  IAToken public aToken;
  ILendingPoolAddressesProvider public aaveAddressProvider;

  /**
   * @notice Construct a new Aave reward token
   * @param _name ERC-20 name of this token
   * @param _symbol ERC-20 symbol of this token
   * @param _aToken Aave's Protocol aToken, (eg aUSDC for underlying USDC)
   * @param _aaveAddressProvider Aave's Address Provider: data source for Aave smart contracts addresses
   * @param _delegate The address of reward owner
   */
  constructor(
    string memory _name,
    string memory _symbol,
    IAToken _aToken,
    ILendingPoolAddressesProvider _aaveAddressProvider,
    address _delegate
  ) ERC20(_name, _symbol) ContinuousRewardToken(_aToken.UNDERLYING_ASSET_ADDRESS(), _delegate) public {
    require(address(_aaveAddressProvider) != address(0), "AaveRewardToken: aave address provider cannot be zero address");
    
    aToken = _aToken;
    aaveAddressProvider = _aaveAddressProvider;

    IERC20(underlying).approve(address(ILendingPool(aaveAddressProvider.getLendingPool())), type(uint256).max);
  }

  /**
   * @notice Annual Percentage Reward for the specific reward token. In Reward Token per Locked underlying per year. (eg AAVE/ (USDC locked per year))
   * @param token Reward token address
   * @dev  When reward Token = underlying (eg AAVE mining on aAAVE), rate is the addition of deposit rate and reward rate.
   * @return times 10^18. E.g. 150000000000000000 => 0.15 RewardToken per Locked underlying per year.
   */
  function _rate(address token) override internal view returns (uint256) {
    require (token != address(0), "AaveRewardToken: token cannot be zero address");

    (address rewardContract, address rewardToken) = getIncentivesAddresses();
    require(
      token == underlying ||
      token == rewardToken,
      "AaveRewardToken: rate token address must be either underlying or reward token address"
    );

    uint256 currentRate = 0;
    if (token == rewardToken) {
      currentRate = _getRewardRate(rewardContract, rewardToken);
    }
    if (token == underlying) {
      currentRate = currentRate.add(_getDepositRate());
    }
    return currentRate;
  }

  /**
   * @notice get the addresses of an underlying incentivized campaign. The incentives contract and the rewarded token.
   * @return address of the IncentivesController and address of the token given as reward.
   */
  function getIncentivesAddresses() public view returns (address, address) {
    try aToken.getIncentivesController() returns (address controller) {
      return controller == address(0) ? (address(0), address(0)) : (
        controller,
        IAaveIncentivesController(controller).REWARD_TOKEN()
      );
    } catch {
      return(address(0), address(0));
    }
  }

  /**
   * @notice Get the interest rate per year (ie 0.10 USDC per USDC locked for 1 year)
   * @return the deposit rate
   */
  function getDepositRate() public view returns (uint256) {
    return _getDepositRate();
  }

  /**
   * @notice Get the incentives rate per year (ie 0.0010 AAVE rewarder per USDC locked for 1 year)
   * @return the reward rate
   */
  function getRewardRate() external view returns (uint256) {
    (address rewardContract, address rewardToken) = getIncentivesAddresses();
      return _getRewardRate(rewardContract, rewardToken);
  }

  function _getRewardRate(address rewardContract, address rewardToken) internal view returns (uint256) {
    require(rewardContract != address(0) &&
      rewardToken != address(0),
      "AaveRewardToken: reward contract and reward token cannot be a zero address"
    );
    
    (uint128 emissionPerSecond, , ) = IAaveIncentivesController(rewardContract).assets(address(aToken));
    return(
      uint256(emissionPerSecond).mul(365 days)
      .mul(REWARD_RATE_DECIMAL_PRECISION)
      .mul(10**uint256(aToken.decimals()))
      .div(aToken.totalSupply()) // TVL
      // IERC20 interface does not have decimals, IAToken does
      .div(10**uint256(IAToken(rewardToken).decimals()))
    );
  }

  function _getDepositRate() internal view returns (uint256) {
    // `currentLiquidityRate` is in RAY units (10^27), so we divide by the WAD_RAY ratio to get 10^18 units
    return (
      uint256(
        ILendingPool(aaveAddressProvider.getLendingPool())
        .getReserveData(underlying)
        .currentLiquidityRate
      ).div(WAD_RAY_RATIO)
    );
  }


  function _supply(uint256 amount) override internal {
    ILendingPool(aaveAddressProvider.getLendingPool()).deposit(underlying, amount, address(this), REFERRAL_CODE);
  }

  function _redeem(uint256 amount) override internal {
    ILendingPool(aaveAddressProvider.getLendingPool()).withdraw(underlying, amount, address(this));
  }

  function _claim(address claimToken, uint256 amount) override internal {
    (address rewardContract, address rewardToken) = getIncentivesAddresses();
    require(
      claimToken == underlying ||
      claimToken == rewardToken,
      "AaveRewardToken: claim token address must be either underlying or reward token address"
    );

    uint256 asked = amount;
    // claiming on priority on Liquidity programs
    if (claimToken == rewardToken) {
      address[] memory assets = new address[](1);
      assets[0] = address(aToken);
      uint256 claimed = IAaveIncentivesController(rewardContract)
        .claimRewards(assets, amount, address(this));
      asked = asked.sub(claimed);
    }
    if (claimToken == underlying) {
      ILendingPool(aaveAddressProvider.getLendingPool()).withdraw(underlying, asked, address(this));
    }
  }

  function _balanceOfReward(address token) override internal view returns (uint256) {
    (address rewardContract, address rewardToken) = getIncentivesAddresses();
    require(
      token == underlying ||
      token == rewardToken,
      "AaveRewardToken: reward token address must be either underlying or reward token address"
    );

    uint256 balance = 0;

    if (token == rewardToken) {
      address[] memory assets = new address[](1);
      assets[0] = address(aToken);
      balance = IAaveIncentivesController(rewardContract)
          .getRewardsBalance(assets, address(this));
    }
    if (token == underlying) {
      uint256 totalSupply = totalSupply();
      balance = balance.add(aToken.balanceOf(address(this)));
      balance = totalSupply > balance ? 0 : balance.sub(totalSupply);
    }
    return balance;
  }

  function _rewardTokens() override internal view returns (address[] memory) {
    (, address rewardToken) = getIncentivesAddresses();
    if (rewardToken == address(0)) {
      address[] memory token = new address[](1);
      token[0] = underlying;
      return token;
    }
    address[] memory tokens = new address[](2);
    (tokens[0], tokens[1]) = (underlying, rewardToken);
    return tokens;
  }
}
