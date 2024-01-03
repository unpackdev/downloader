// SPDX-License-Identifier: Apache-2.0-with-puul-exception
pragma solidity >=0.6.12;
import "./SafeMath.sol";
import "./Address.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./Console.sol";
import "./IFarm.sol";
import "./IPool.sol";
import "./Fees.sol";
import "./PuulRewards.sol";

contract BaseFarm is IFarm, PuulRewards, ReentrancyGuard {
  using Address for address;
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  Fees _fees;
  IERC20 _pool;
  IERC20 _staking;
  address _targetFarm;

  constructor (address pool, address farm, address staking, address[] memory rewards, address fees) public {
    _targetFarm = farm;
    _fees = Fees(fees);
    _pool = IERC20(pool);
    _staking = IERC20(staking);
    _addRewards(rewards);
  }

  modifier onlyPool() {
    require(msg.sender == address(_pool), "!pool");
    _;
  }

  function setupRoles(address defaultAdmin, address admin, address extract) onlyDefaultAdmin external {
    _setup(ROLE_ADMIN, admin);
    _setup(ROLE_EXTRACT, extract);
    _setupDefaultAdmin(defaultAdmin);
  }

  function addReward(address token) onlyHarvester nonReentrant override external {
    _addReward(token);
    IPool(address(_pool)).rewardAdded(token);
  }

  function rewardAdded(address token) onlyFarm nonReentrant external override {
    _addReward(token);
    IPool(address(_pool)).rewardAdded(token);
  }

  function _deposit(uint256 amount) internal virtual {}

  function earn() onlyPool nonReentrant external override {
    uint256 amount = _staking.balanceOf(address(this));
    _staking.safeApprove(address(_targetFarm), 0);
    _staking.safeApprove(address(_targetFarm), amount * 2);
    _deposit(amount);
  }

  function _harvest() internal virtual {}

  function convertFees(Fees fees, IERC20 reward, uint256 amount) internal returns(uint256 feeAmt) {
    feeAmt = fees.rewardFee(amount);
    if (feeAmt > 0) {
      address dest = fees.reward();
      require(dest != address(0));
      reward.safeTransfer(dest, feeAmt);
    }
  }

  function harvest() onlyPool nonReentrant external override {
    _harvest();
    for (uint i = 0; i < _rewards.length; i++) {
      IERC20 reward = IERC20(_rewards[i]);
      uint256 amount = reward.balanceOf(address(this));
      if (amount > 0) {
        uint256 fees = convertFees(_fees, reward, amount);
        reward.safeTransfer(address(_pool), amount - fees);
      }
    }
  }

  function _withdraw(uint256 amount) internal virtual {}

  function withdraw(uint256 amount) onlyPool nonReentrant external override {
    _withdraw(amount);
    uint256 bal = _staking.balanceOf(address(this));
    _staking.safeTransfer(address(_pool), bal);
  }

  function _tokenInUse(address token) override virtual internal view returns(bool) {
    return token == address(_staking) || PuulRewards._tokenInUse(token);
  }
  
}