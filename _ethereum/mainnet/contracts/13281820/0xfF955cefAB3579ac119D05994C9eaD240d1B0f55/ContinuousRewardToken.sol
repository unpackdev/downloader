// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.6.12;

import "./ERC20.sol";
import "./SafeERC20.sol";

import "./IContinuousRewardToken.sol";

/**
 * @title ContinuousRewardToken contract
 * @notice ERC20 token which wraps underlying protocol rewards
 */
abstract contract ContinuousRewardToken is ERC20, IContinuousRewardToken {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  /// @notice The address of underlying token
  address public override underlying;
  /// @notice The admin of reward token
  address public override admin;
  /// @notice The current owner of all rewards
  address public override delegate;
  /// @notice Unclaimed rewards of all previous owners: reward token => (owner => amount)
  mapping(address => mapping(address => uint256)) public override unclaimedRewards;
  /// @notice Total amount of unclaimed rewards: (reward token => amount)
  mapping(address => uint256) public override totalUnclaimedRewards;

  /**
   * @notice Construct a new Continuous reward token
   * @param _underlying The address of underlying token
   * @param _delegate The address of reward owner
   */
  constructor(address _underlying, address _delegate) public {
    admin = msg.sender;
    require(_underlying != address(0), "ContinuousRewardToken: underlying cannot be zero address");
    require(_delegate != address(0), "ContinuousRewardToken: delegate cannot be zero address");

    delegate = _delegate;
    underlying = _underlying;
  }

  /**
   * @notice Annual Percentage Reward for the specific reward token. Measured in relation to the base units of the underlying asset vs base units of the accrued reward token.
   * @param rewardToken Reward token address
   * @return APY times 10^18
   */
  function rate(address rewardToken) override external view returns (uint256) {
    return _rate(rewardToken);
  }

  function _rate(address rewardToken) virtual internal view returns (uint256);

  /**
   * @notice Supply a specified amount of underlying tokens and receive back an equivalent quantity of CB-CR-XX-XX tokens
   * @param receiver Account to credit CB-CR-XX-XX tokens to
   * @param amount Amount of underlying token to supply
   */
  function supply(address receiver, uint256 amount) override external {
    require(amount != 0, "ContinuousRewardToken: supply amount cannot be zero");
    
    IERC20(underlying).safeTransferFrom(msg.sender, address(this), amount);

    _mint(receiver, amount);
    _supply(amount);

    emit Supply(msg.sender, receiver, amount);
  }

  function _supply(uint256 amount) virtual internal;

  /**
   * @notice Reward tokens that may be accrued as rewards
   * @dev It's the responsibility of each implemantation to limit the size of the address array returned
   * @return Exhaustive list of all reward token addresses
   */
  function rewardTokens() override external view returns (address[] memory) {
    return _rewardTokens();
  }

  function _rewardTokens() virtual internal view returns (address[] memory);

  /**
   * @notice Amount of reward for the given reward token
   * @param rewardToken The address of reward token
   * @param account The account for which reward balance is checked
   * @return reward balance of token the specified account has
   */
  function balanceOfReward(address rewardToken, address account) override public view returns (uint256) {
    require(rewardToken != address(0), "ContinuousRewardToken: reward token cannot be zero address");

    if (account == delegate) {
      return _balanceOfReward(rewardToken).sub(totalUnclaimedRewards[rewardToken]);
    }
    return unclaimedRewards[rewardToken][account];
  }

  function _balanceOfReward(address rewardToken) virtual internal view returns (uint256);

  /**
   * @notice Redeem a specified amount of underlying tokens by burning an equivalent quantity of CB-CR-XX-XX tokens. Does not redeem reward tokens
   * @param receiver Account to credit underlying tokens to
   * @param amount Amount of underlying token to redeem
   */
  function redeem(
    address receiver,
    uint256 amount
  ) override public {
    _burn(msg.sender, amount);
    _redeem(amount);

    IERC20(underlying).safeTransfer(receiver, amount);

    emit Redeem(msg.sender, receiver, amount);
  }

  function _redeem(uint256 amount) virtual internal;

  /**
   * @notice Claim accrued reward in one or more reward tokens
   * @dev All params must have the same array length
   * @param receivers List of accounts to credit claimed tokens to
   * @param tokens Reward token addresses
   * @param amounts Amounts of each reward token to claim
   */
  function claim(
    address[] calldata receivers,
    address[] calldata tokens,
    uint256[] calldata amounts
  ) override public {
    require(receivers.length == tokens.length && receivers.length == amounts.length, "ContinuousRewardToken: receivers, tokens, and amounts arrays lengths don't match");

    for (uint256 i = 0; i < receivers.length; i++) {
      address receiver = receivers[i];
      address claimToken = tokens[i];
      uint256 amount = amounts[i];
      uint256 rewardBalance = balanceOfReward(claimToken, msg.sender);

      require(claimToken != address(0), "ContinuousRewardToken: claim token cannot be zero address");

      uint256 claimAmount = amount == type(uint256).max ? rewardBalance : amount;
      require(rewardBalance >= claimAmount, "ContinuousRewardToken: claim amount is greater than reward balance");

      // If caller is one of previous owners, update unclaimed rewards data
      if (msg.sender != delegate) {
        unclaimedRewards[claimToken][msg.sender] = rewardBalance.sub(claimAmount);
        totalUnclaimedRewards[claimToken] = totalUnclaimedRewards[claimToken].sub(claimAmount);
      }

      _claim(claimToken, claimAmount);

      IERC20(claimToken).safeTransfer(receiver, claimAmount);

      emit Claim(msg.sender, receiver, claimToken, claimAmount);
    }
  }

  function _claim(address claimToken, uint256 amount) virtual internal;

  /**
   * @notice Atomic redeem and claim in a single transaction
   * @dev receivers[0] corresponds to the address that the underlying token is redeemed to. receivers[1:n-1] hold the to addresses for the reward tokens respectively.
   * @param receivers       List of accounts to credit tokens to
   * @param amounts         List of amounts to credit
   * @param claimTokens     Reward token addresses
   */
  function redeemAndClaim(
    address[] calldata receivers,
    uint256[] calldata amounts,
    address[] calldata claimTokens
  ) override external {
    redeem(receivers[0], amounts[0]);
    claim(receivers[1:], claimTokens, amounts[1:]);
  }

  /**
   * @notice Updates reward owner address
   * @dev Only callable by admin
   * @param newDelegate New reward owner address
   */
  function updateDelegate(address newDelegate) override external onlyAdmin {
    require(newDelegate != delegate, "ContinuousRewardToken: new delegate address cannot be the same as the old delgate address");
    require(newDelegate != address(0), "ContinuousRewardToken: new delegate address cannot be zero address");

    address oldDelegate = delegate;

    address[] memory allRewardTokens = _rewardTokens();
    for (uint256 i = 0; i < allRewardTokens.length; i++) {
      address rewardToken = allRewardTokens[i];

      uint256 rewardBalance = balanceOfReward(rewardToken, oldDelegate);
      unclaimedRewards[rewardToken][oldDelegate] = rewardBalance;
      totalUnclaimedRewards[rewardToken] = totalUnclaimedRewards[rewardToken].add(rewardBalance);

      // If new owner used to be reward owner in the past, transfer back his unclaimed rewards to himself
      uint256 prevBalance = unclaimedRewards[rewardToken][newDelegate];
      if (prevBalance > 0) {
        unclaimedRewards[rewardToken][newDelegate] = 0;
        totalUnclaimedRewards[rewardToken] = totalUnclaimedRewards[rewardToken].sub(prevBalance);
      }
    }

    delegate = newDelegate;

    emit DelegateUpdated(oldDelegate, newDelegate);
  }

  /**
   * @notice Updates the admin address
   * @dev Only callable by admin
   * @param newAdmin New admin address
   */
  function transferAdmin(address newAdmin) override external onlyAdmin {
    require(newAdmin != admin, "ContinuousRewardToken: new admin address is the same as the old admin address");
    address previousAdmin = admin;

    admin = newAdmin;

    emit AdminTransferred(previousAdmin, newAdmin);
  }

  modifier onlyAdmin {
    require(msg.sender == admin, "ContinuousRewardToken: msg.sender is not an admin");
    _;
  }
}
