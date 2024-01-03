// SPDX-License-Identifier: Apache-2.0-with-puul-exception
pragma solidity >=0.6.12;
import "./SafeMath.sol";
import "./Address.sol";
import "./SafeCast.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./UniswapHelper.sol";
import "./Console.sol";
import "./IFarm.sol";
import "./Fees.sol";
import "./IPool.sol";
import "./IPoolWithdraw.sol";
import "./PuulRewards.sol";

contract FarmEndpointV2 is IFarm, PuulRewards, ReentrancyGuard {
  using Address for address;
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  address _pool;
  mapping (address => bool) _validPoolsMap;

  constructor (address pool, address[] memory rewards) public {
    _pool = pool;
    _setupRole(ROLE_ADMIN, msg.sender);
    _setupRole(ROLE_HARVESTER, msg.sender);
    _addRewards(rewards);
  }

  modifier onlyPool() {
    require(msg.sender == _pool, "!pool");
    _;
  }

  modifier onlyValidPool(address pool) {
    require(_validPoolsMap[pool], "!valid pool");
    _;
  }

  function setupRoles(address defaultAdmin, address admin, address extract, address harvester) onlyDefaultAdmin external {
    _setup(ROLE_ADMIN, admin);
    _setup(ROLE_EXTRACT, extract);
    _setup(ROLE_HARVESTER, harvester);
    _setupAdmin(admin);
    _setupDefaultAdmin(defaultAdmin);
  }

  function addReward(address token) onlyHarvester external override virtual {
    if (_addReward(token)) {
      IPool(_pool).rewardAdded(token);
    }
  }

  function addPool(address pool) onlyHarvester external {
    _validPoolsMap[pool] = true;
  }

  function removePool(address pool) onlyHarvester external {
    _validPoolsMap[pool] = false;
  }

  function convertFees(Fees fees, IERC20 reward, uint256 amount) internal returns(uint256 feeAmt) {
    feeAmt = fees.rewardFee(amount);
    if (feeAmt > 0) {
      address dest = fees.reward();
      require(dest != address(0));
      reward.safeTransfer(dest, feeAmt);
    }
  }

  function harvest() onlyPool nonReentrant external override {
    for (uint i = 0; i < _rewards.length; i++) {
      IERC20 reward = IERC20(_rewards[i]);
      uint256 amount = reward.balanceOf(address(this));
      if (amount > 0) {
        Fees poolFees = Fees(IPoolWithdraw(_pool).getFees());
        uint256 fees = convertFees(poolFees, reward, amount);
        reward.safeTransfer(address(_pool), amount - fees);
      }
    }
  }

  function earn() onlyPool nonReentrant external override {
    // not used
  }

  function withdraw(uint256 amount) onlyPool nonReentrant external override {
    // not used
  }

  function convertRewardFees(address pool, address help, uint256[] memory amounts, uint256[] memory min) onlyHarvester onlyValidPool(pool) virtual external returns(int256[] memory out) {
    require(amounts.length == min.length, 'amounts!=min');
    address token = Fees(IPoolWithdraw(pool).getFees()).currency();
    require(_rewardsMap[IERC20(token)] > 0, 'fee!=reward');
    address[] memory rewards = IPoolWithdraw(pool).rewards();
    require(amounts.length == rewards.length, 'amounts!=rewards');

    UniswapHelper helper = UniswapHelper(help);
    out = new int[](rewards.length);
    for (uint256 i = 0; i < rewards.length; i++) {
      out[i] = -1;
      IERC20 reward = IERC20(rewards[i]);
      if (_rewardsMap[reward] == 0 && amounts[i] > 0) { // only convert if needed
        string memory path = Path.path(address(reward), token);
        uint256 bef = reward.balanceOf(help);
        reward.safeTransfer(help, amounts[i]);
        uint256 aft = reward.balanceOf(help);
        amounts[i] = aft.sub(bef, '!reward');
        out[i] = SafeCast.toInt256(helper.swap(path, amounts[i], min[i], address(this)));
      } 
    }
  }

  function withdrawFees(address pool, uint256 amount, uint256 minA, uint256 minB, uint256 minOutA, uint256 minOutB) onlyHarvester onlyValidPool(pool) virtual external {
    address token = Fees(IPoolWithdraw(pool).getFees()).currency();
    require(_rewardsMap[IERC20(token)] > 0, 'fee!=reward');
    IPoolWithdraw(pool).withdrawFeesToToken(amount, token, minA, minB, minOutA, minOutB);
  }

  function withdrawFeesRaw(address pool) onlyHarvester onlyValidPool(pool) virtual external {
    IPoolWithdraw(pool).withdrawFees();
  }

  function updateAndClaim(address pool) onlyHarvester onlyValidPool(pool) virtual external {
    IPoolWithdraw(pool).updateAndClaim();
  }
    
}