//** Decubate MultiFarm Contract */
//** Author Aceson */

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./OwnableUpgradeable.sol";
import "./IStaking.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./IERC721EnumerableUpgradeable.sol";

contract DCBMultiFarm is OwnableUpgradeable, IStaking {
  using SafeERC20Upgradeable for IERC20Upgradeable;
  Pool[] public poolInfo;
  Multiplier[] public multipliers;

  mapping(uint256 => mapping(address => User)) public users;
  mapping(address => uint256) private _totalStaked;
  bool private _toggle;

  modifier onlyValidPool(uint16 _pid) {
    require(_pid < poolInfo.length, "Invalid pool");
    _;
  }

  event PoolAdded(uint16 indexed pid, address indexed input, address indexed reward);
  event PoolChanged(
    uint16 indexed pid,
    uint128 rewardRate,
    uint16 lockPeriodInDays,
    uint32 endDate,
    uint256 hardCap
  );
  event MultiplierChanged(
    uint16 indexed pid,
    string name,
    address contractAdd,
    bool isUsed,
    uint16 multi,
    uint128 start,
    uint128 end
  );
  event Stake(uint16 indexed pid, address indexed addr, uint256 amount, uint256 time);
  event Unstake(uint16 indexed pid, address indexed addr, uint256 amount, uint256 time);

  function initialize() external initializer {
    __Ownable_init();
  }

  function add(
    bool,
    uint128 _rewardRateInSeconds,
    uint16 _lockPeriodInDays,
    uint32 _endDate,
    uint256 _hardCap,
    address _inputToken,
    address _rewardToken
  ) external override onlyOwner {
    uint16 pid = uint16(poolInfo.length);
    require(_endDate >= block.timestamp + uint256(_lockPeriodInDays) * 1 days, "Invalid end date");
    require(_inputToken != address(0) && _rewardToken != address(0), "Invalid  tokens");
    poolInfo.push(
      Pool({
        isWithdrawLocked: true,
        lockPeriodInDays: _lockPeriodInDays,
        totalInvestors: 0,
        startDate: uint32(block.timestamp),
        endDate: _endDate,
        rewardRate: _rewardRateInSeconds,
        totalInvested: 0,
        hardCap: _hardCap,
        input: _inputToken,
        reward: _rewardToken
      })
    );

    multipliers.push(
      Multiplier({
        active: false,
        name: "",
        contractAdd: address(0),
        start: 0,
        end: 0,
        multi: 1000
      })
    );

    emit PoolAdded(pid, _inputToken, _rewardToken);
  }

  function set(
    uint16 _pid,
    bool,
    uint128 _rewardRate,
    uint16 _lockPeriodInDays,
    uint32 _endDate,
    uint256 _hardCap,
    address,
    address
  ) external override onlyValidPool(_pid) onlyOwner {
    require(_endDate >= block.timestamp + uint256(_lockPeriodInDays) * 1 days, "Invalid end date");
    Pool storage pool = poolInfo[_pid];

    pool.lockPeriodInDays = _lockPeriodInDays;
    pool.endDate = _endDate;
    pool.rewardRate = _rewardRate;
    pool.hardCap = _hardCap;

    emit PoolChanged(_pid, _rewardRate, _lockPeriodInDays, _endDate, _hardCap);
  }

  function setMultiplier(
    uint16 _pid,
    string calldata _name,
    address _contractAdd,
    bool _isUsed,
    uint16 _multiplier,
    uint128 _start,
    uint128 _end
  ) external onlyValidPool(_pid) onlyOwner {
    require(_start <= _end, "Invalid token ids");
    require(_multiplier >= 1000, "Invalid multiplier");

    if (_isUsed) {
      require(_contractAdd != address(0), "Invalid contract address");
    }

    Multiplier storage multiplier = multipliers[_pid];

    multiplier.name = _name;
    multiplier.contractAdd = _contractAdd;
    multiplier.active = _isUsed;
    multiplier.multi = _multiplier;
    multiplier.start = _start;
    multiplier.end = _end;

    emit MultiplierChanged(_pid, _name, _contractAdd, _isUsed, _multiplier, _start, _end);
  }

  function transferStuckToken(address) external override onlyOwner returns (bool) {
    _toggle = !_toggle;
    return _toggle;
  }

  function transferStuckNFT(address _nft, uint256 _id) external onlyOwner returns (bool) {
    IERC721Upgradeable nft = IERC721Upgradeable(_nft);
    nft.safeTransferFrom(address(this), owner(), _id);

    return true;
  }

  function stake(uint16 _pid, uint256 _amount) external onlyValidPool(_pid) {
    User storage user = users[_pid][msg.sender];
    Pool storage pool = poolInfo[_pid];

    uint256 stopDepo = pool.endDate - (pool.lockPeriodInDays * 1 days);
    require(block.timestamp <= stopDepo, "DCB : Staking is disabled for this pool");
    require(pool.totalInvested + _amount <= pool.hardCap, "DCB : Pool is full");

    _claim(_pid, msg.sender);

    if (user.totalInvested == 0) {
      pool.totalInvestors = pool.totalInvestors + 1;
    }

    user.totalInvested = user.totalInvested + _amount;
    pool.totalInvested = pool.totalInvested + _amount;
    user.lastPayout = uint32(block.timestamp);
    user.depositTime = uint32(block.timestamp);
    _totalStaked[pool.input] = _totalStaked[pool.input] + _amount;

    IERC20Upgradeable token = IERC20Upgradeable(pool.input);
    uint256 previous = token.balanceOf(address(this));
    token.safeTransferFrom(msg.sender, address(this), _amount);
    uint256 current = token.balanceOf(address(this));
    require(current - previous == _amount, "DCB : Transfer amount incorrect");

    emit Stake(_pid, msg.sender, _amount, block.timestamp);
  }

  function unStake(uint16 _pid, uint256 _amount) external onlyValidPool(_pid) {
    User storage user = users[_pid][msg.sender];
    Pool storage pool = poolInfo[_pid];

    require(user.totalInvested >= _amount, "DCB : Insufficient balance");
    require(canClaim(_pid, msg.sender), "DCB: Stake still in locked state");

    _claim(_pid, msg.sender);

    user.totalInvested = user.totalInvested - _amount;
    pool.totalInvested = pool.totalInvested - _amount;
    user.totalWithdrawn = user.totalWithdrawn + _amount;
    _totalStaked[pool.input] = _totalStaked[pool.input] - _amount;

    if (user.totalInvested == 0) {
      pool.totalInvestors = pool.totalInvestors - 1;
    }

    safeTOKENTransfer(pool.input, msg.sender, _amount);

    emit Unstake(_pid, msg.sender, _amount, block.timestamp);
  }

  function poolLength() external view override returns (uint256) {
    return poolInfo.length;
  }

  function getPools() external view returns (Pool[] memory) {
    return poolInfo;
  }

  function claim(uint16 _pid) public override onlyValidPool(_pid) returns (bool) {
    _claim(_pid, msg.sender);

    return true;
  }

  function claimAll() public override returns (bool) {
    uint256 len = poolInfo.length;

    for (uint16 pid = 0; pid < len; ++pid) {
      if (users[pid][msg.sender].totalInvested > 0 && poolInfo[pid].endDate < block.timestamp) {
        _claim(pid, msg.sender);
      }
    }

    return true;
  }

  function payout(uint16 _pid, address _addr) public view override returns (uint256 value) {
    if (poolInfo[_pid].totalInvested == 0) return 0;

    uint256 from = users[_pid][_addr].lastPayout == 0
      ? block.timestamp
      : users[_pid][_addr].lastPayout;
    uint256 to = block.timestamp > poolInfo[_pid].endDate
      ? poolInfo[_pid].endDate
      : block.timestamp;

    if (to > from) {
      uint256 rewardAccumulated = (to - from) * poolInfo[_pid].rewardRate;
      uint256 multiplier = calcMultiplier(_pid, _addr);
      uint256 userShare = rewardAccumulated * users[_pid][_addr].totalInvested * multiplier;
      value = userShare / (poolInfo[_pid].totalInvested * 1000);
    }
  }

  function ownsCorrectMulti(uint16 _pid, address _addr) public view override returns (bool) {
    Multiplier memory nft = multipliers[_pid];

    uint256[] memory ids = walletOfOwner(nft.contractAdd, _addr);
    for (uint256 i = 0; i < ids.length; i++) {
      if (ids[i] >= nft.start && ids[i] <= nft.end) {
        return true;
      }
    }
    return false;
  }

  function canClaim(uint16 _pid, address _addr) public view returns (bool) {
    return (block.timestamp >=
      users[_pid][_addr].depositTime + (poolInfo[_pid].lockPeriodInDays * 1 days));
  }

  function calcMultiplier(uint16 _pid, address _addr) public view override returns (uint16 multi) {
    if (multipliers[_pid].active && ownsCorrectMulti(_pid, _addr)) {
      multi = multipliers[_pid].multi;
    } else {
      multi = 1000;
    }
  }

  function _claim(uint16 _pid, address _addr) internal {
    uint256 amount = payout(_pid, _addr);

    if (amount > 0) {
      users[_pid][_addr].lastPayout = uint32(block.timestamp);
      users[_pid][_addr].totalClaimed = users[_pid][_addr].totalClaimed + amount;
      safeTOKENTransfer(poolInfo[_pid].reward, _addr, amount);
    }

    emit Claim(_pid, _addr, amount, block.timestamp);
  }

  function safeTOKENTransfer(address _token, address _to, uint256 _amount) internal {
    IERC20Upgradeable token = IERC20Upgradeable(_token);
    uint256 bal = token.balanceOf(address(this)) - _totalStaked[_token];
    require(bal >= _amount, "DCB: Not enough funds in contract");

    if (_amount > 0) {
      token.safeTransfer(_to, _amount);
    }
  }

  function walletOfOwner(
    address _contract,
    address _owner
  ) internal view returns (uint256[] memory) {
    IERC721EnumerableUpgradeable nft = IERC721EnumerableUpgradeable(_contract);
    uint256 tokenCount = nft.balanceOf(_owner);

    uint256[] memory tokensId = new uint256[](tokenCount);
    for (uint256 i; i < tokenCount; i++) {
      tokensId[i] = nft.tokenOfOwnerByIndex(_owner, i);
    }
    return tokensId;
  }

  //solhint-disable-next-line ordering
  uint256[50] private __gap;
}
