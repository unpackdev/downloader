// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./Ownable.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";
import "./NativeRewards.sol";
import "./TokenRewards.sol";

contract StakingPool is IStakingPool, ERC20, Ownable {
  using SafeERC20 for IERC20;

  IERC20 public immutable STAKING_TOKEN;
  NativeRewards public immutable NATIVE_REWARDS;
  TokenRewards public immutable TOKEN_REWARDS;

  uint256 public timelockSeconds;
  mapping(address => uint256) public walletStakedTime;

  event SetRewardsFromError(address indexed _from);
  event SetRewardsToError(address indexed _to);
  event Stake(address indexed owner, uint256 amount);
  event Unstake(address indexed owner, uint256 amount);

  modifier onlyRewards() {
    require(
      _msgSender() == address(NATIVE_REWARDS) ||
        _msgSender() == address(TOKEN_REWARDS),
      'REWARDS'
    );
    _;
  }

  constructor(
    string memory _name,
    string memory _symbol,
    address _stakingToken,
    address _rewardsToken,
    uint256 _timelock
  ) ERC20(_name, _symbol) {
    STAKING_TOKEN = IERC20(_stakingToken);
    NATIVE_REWARDS = new NativeRewards(address(this));
    TOKEN_REWARDS = new TokenRewards(address(this), _rewardsToken);
    timelockSeconds = _timelock;
  }

  function decimals() public view override returns (uint8) {
    return 9;
  }

  function stake(uint256 _amount) external {
    walletStakedTime[_msgSender()] = block.timestamp;
    STAKING_TOKEN.safeTransferFrom(_msgSender(), address(this), _amount);
    _mint(_msgSender(), _amount);
    emit Stake(_msgSender(), _amount);
  }

  function unstake(uint256 _amount) external {
    _burn(_msgSender(), _amount);
    STAKING_TOKEN.safeTransfer(_msgSender(), _amount);
    emit Unstake(_msgSender(), _amount);
  }

  function resetWalletStakedTime(
    address _wallet
  ) external override onlyRewards {
    walletStakedTime[_wallet] = block.timestamp;
  }

  function setTimelockSeconds(uint256 _seconds) external onlyOwner {
    timelockSeconds = _seconds;
  }

  function _afterTokenTransfer(
    address _from,
    address _to,
    uint256 _amount
  ) internal override {
    if (_from != address(0) && _from != address(0xdead)) {
      bool _early = walletStakedTime[_from] == 0 ||
        block.timestamp < walletStakedTime[_from] + timelockSeconds;
      require(!_early, 'EARLYUNSTAKE');
      try NATIVE_REWARDS.setShare(_from, _amount, true) {} catch {
        emit SetRewardsFromError(_from);
      }
      TOKEN_REWARDS.setShare(_from, _amount, true);
    }
    if (_to != address(0) && _to != address(0xdead)) {
      try NATIVE_REWARDS.setShare(_to, _amount, false) {} catch {
        emit SetRewardsToError(_to);
      }
      TOKEN_REWARDS.setShare(_to, _amount, false);
      walletStakedTime[_to] = walletStakedTime[_from] > walletStakedTime[_to]
        ? walletStakedTime[_from]
        : walletStakedTime[_to];
    }
  }
}
