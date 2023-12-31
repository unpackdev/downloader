//** Decubate Staking Contract */
//** Author : Aceson */

//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

import "./IERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./IERC721EnumerableUpgradeable.sol";
import "./InterestHelper.sol";
import "./IDecubateMasterChef.sol";

contract DecubateMasterChef is
  Initializable,
  OwnableUpgradeable,
  InterestHelper,
  IDecubateMasterChef
{
  using SafeMathUpgradeable for uint256;
  using SafeMathUpgradeable for uint16;

  /**
   *
   * @dev PoolInfo reflects the info of each pools
   *
   * If APY is 12%, we provide 120 as input. lockPeriodInDays
   * would be the number of days which the claim is locked.
   * So if we want to lock claim for 1 month, lockPeriodInDays would be 30.
   *
   * @param {apy} Percentage of yield produced by the pool
   * @param {nft} Multiplier for apy if user holds nft
   * @param {lockPeriodInDays} Amount of time claim will be locked
   * @param {totalDeposit} Total deposit in the pool
   * @param {startDate} starting time of pool
   * @param {endDate} ending time of pool in unix timestamp
   * @param {minContrib} Minimum amount to be staked
   * @param {maxContrib} Maximum amount that can be staked
   * @param {hardCap} Maximum amount a pool can hold
   * @param {token} Token used as deposit/reward
   *
   */

  struct Pool {
    uint256 apy;
    uint256 lockPeriodInDays;
    uint256 totalDeposit;
    uint256 startDate;
    uint256 endDate;
    uint256 hardCap;
    address token;
  }

  address public compounderContract; //Auto compounder
  address private feeAddress; //Address which receives fee
  uint8 private feePercent; //Percentage of fee deducted (/1000)

  mapping(uint256 => mapping(address => User)) public users;
  mapping(address => uint256) public maxTransferAmount;

  Pool[] public poolInfo;
  NFTMultiplier[] public nftInfo;

  event Stake(address indexed addr, uint256 amount, uint256 time);
  event Claim(address indexed addr, uint256 amount, uint256 time);
  event Reinvest(address indexed addr, uint256 amount, uint256 time);
  event Unstake(address indexed addr, uint256 amount, uint256 time);

  function initialize() external initializer {
    __Ownable_init();
    feeAddress = msg.sender;
    feePercent = 5;
  }

  /**
   *
   * @dev update fee values
   *
   */
  function updateFeeValues(uint8 _feePercent, address _feeWallet) external onlyOwner {
    feePercent = _feePercent;
    feeAddress = _feeWallet;
  }

  /**
   *
   * @dev update compounder contract
   *
   */
  function updateCompounder(address _compounder) external override onlyOwner {
    compounderContract = _compounder;
  }

  /**
   *
   * @dev Allow owner to transfer token from contract
   *
   * @param {address} contract address of corresponding token
   * @param {uint256} amount of token to be transferred
   *
   * This is a generalized function which can be used to transfer any accidentally
   * sent (including DCB) out of the contract to wowner
   *
   */
  function transferToken(address _addr, uint256 _amount) external onlyOwner returns (bool) {
    IERC20Upgradeable token = IERC20Upgradeable(_addr);
    bool success = token.transfer(address(owner()), _amount);
    return success;
  }

  /**
   *
   * @dev add new period to the pool, only available for owner
   *
   */
  function add(
    uint256 _apy,
    uint256 _lockPeriodInDays,
    uint256 _endDate,
    uint256 _hardCap,
    address _token
  ) external override onlyOwner {
    poolInfo.push(
      Pool({
        apy: _apy,
        lockPeriodInDays: _lockPeriodInDays,
        totalDeposit: 0,
        startDate: block.timestamp,
        endDate: _endDate,
        hardCap: _hardCap,
        token: _token
      })
    );

    //Init nft struct with dummy data
    nftInfo.push(
      NFTMultiplier({
        active: false,
        name: "",
        contractAdd: address(0),
        startIdx: 0,
        endIdx: 0,
        multiplier: 10
      })
    );

    maxTransferAmount[_token] = ~uint256(0);
    _stake(poolLength() - 1, compounderContract, 0, false); //Mock deposit for compounder
  }

  /**
   *
   * @dev update the given pool's Info
   *
   */
  function set(
    uint256 _pid,
    uint256 _apy,
    uint256 _lockPeriodInDays,
    uint256 _endDate,
    uint256 _hardCap,
    uint256 _maxTransfer,
    address _token
  ) external override onlyOwner {
    require(_pid < poolLength(), "Invalid pool Id");

    poolInfo[_pid].apy = _apy;
    poolInfo[_pid].lockPeriodInDays = _lockPeriodInDays;
    poolInfo[_pid].endDate = _endDate;
    poolInfo[_pid].hardCap = _hardCap;
    poolInfo[_pid].token = _token;

    maxTransferAmount[_token] = _maxTransfer;
  }

  /**
   *
   * @dev update the given pool's nft info
   *
   */
  function setNFT(
    uint256 _pid,
    string calldata _name,
    address _contractAdd,
    bool _isUsed,
    uint16 _multiplier,
    uint16 _startIdx,
    uint16 _endIdx
  ) external override onlyOwner {
    NFTMultiplier storage nft = nftInfo[_pid];

    nft.name = _name;
    nft.contractAdd = _contractAdd;
    nft.active = _isUsed;
    nft.multiplier = _multiplier;
    nft.startIdx = _startIdx;
    nft.endIdx = _endIdx;
  }

  /**
   *
   * @dev depsoit tokens to staking for TOKEN allocation
   *
   * @param {_pid} Id of the pool
   * @param {_amount} Amount to be staked
   *
   * @return {bool} Status of stake
   *
   */
  function stake(uint256 _pid, uint256 _amount) external override returns (bool) {
    Pool memory pool = poolInfo[_pid];
    IERC20Upgradeable token = IERC20Upgradeable(pool.token);

    require(
      token.allowance(msg.sender, address(this)) >= _amount,
      "Decubate : Set allowance first!"
    );

    bool success = token.transferFrom(msg.sender, address(this), _amount);
    require(success, "Decubate : Transfer failed");

    reinvest(_pid);

    _stake(_pid, msg.sender, _amount, false);

    return success;
  }

  /**
   *
   * @dev Handle NFT boost of users from compounder
   *
   * @param {_pid} id of the pool
   * @param {_user} user eligible for NFT boost
   * @param {_rewardAmount} Amount of rewards generated
   *
   * @return {uint256} Status of stake
   *
   */
  function handleNFTMultiplier(
    uint256 _pid,
    address _user,
    uint256 _rewardAmount
  ) external override returns (uint256) {
    require(msg.sender == compounderContract, "Only for compounder");
    uint16 multi = calcMultiplier(_pid, _user);

    uint256 multipliedAmount = _rewardAmount.mul(multi).div(10).sub(_rewardAmount);

    if (multipliedAmount > 0) {
      safeTOKENTransfer(poolInfo[_pid].token, _user, multipliedAmount);
    }

    return multipliedAmount;
  }

  /**
   *
   * @dev claim accumulated TOKEN reward for a single pool
   *
   * @param {_pid} pool identifier
   *
   * @return {bool} status of claim
   */

  function claim(uint256 _pid) public override returns (bool) {
    require(canClaim(_pid, msg.sender), "Reward still in locked state");

    _claim(_pid, msg.sender);

    return true;
  }

  /**
   *
   * @dev Reinvest accumulated TOKEN reward for a single pool
   *
   * @param {_pid} pool identifier
   *
   * @return {bool} status of reinvest
   */

  function reinvest(uint256 _pid) public override returns (bool) {
    uint256 amount = payout(_pid, msg.sender);
    if (amount > 0) {
      _stake(_pid, msg.sender, amount, true);
      emit Reinvest(msg.sender, amount, block.timestamp);
    }

    return true;
  }

  /**
   *
   * @dev Reinvest accumulated TOKEN reward for all pools
   *
   * @return {bool} status of reinvest
   */

  function reinvestAll() public override returns (bool) {
    uint256 len = poolInfo.length;
    for (uint256 pid = 0; pid < len; ++pid) {
      reinvest(pid);
    }

    return true;
  }

  /**
   *
   * @dev claim accumulated TOKEN reward from all pools
   *
   * Beware of gas fee!
   *
   */
  function claimAll() public override returns (bool) {
    uint256 len = poolInfo.length;

    for (uint256 pid = 0; pid < len; ++pid) {
      if (canClaim(pid, msg.sender)) {
        _claim(pid, msg.sender);
      }
    }

    return true;
  }

  /**
   *
   * @dev withdraw tokens from Staking
   *
   * @param {_pid} id of the pool
   * @param {_amount} amount to be unstaked
   *
   * @return {bool} Status of stake
   *
   */
  function unStake(uint256 _pid, uint256 _amount) public override returns (bool) {
    User storage user = users[_pid][msg.sender];
    Pool storage pool = poolInfo[_pid];

    require(user.totalInvested >= _amount, "You don't have enough funds");

    require(canClaim(_pid, msg.sender), "Stake still in locked state");

    _claim(_pid, msg.sender);

    safeTOKENTransfer(pool.token, msg.sender, _amount);

    pool.totalDeposit = pool.totalDeposit.sub(_amount);
    user.totalInvested = user.totalInvested.sub(_amount);

    emit Unstake(msg.sender, _amount, block.timestamp);

    return true;
  }

  /**
   *
   * @dev check whether user can claim or not
   *
   * @param {_pid}  id of the pool
   * @param {_addr} address of the user
   *
   * @return {bool} Status of claim
   *
   */

  function canClaim(uint256 _pid, address _addr) public view override returns (bool) {
    User storage user = users[_pid][_addr];
    Pool storage pool = poolInfo[_pid];

    if (msg.sender == compounderContract) {
      return true;
    }

    return (block.timestamp >= user.depositTime.add(pool.lockPeriodInDays.mul(1 days)));
  }

  /**
   *
   * @dev check whether user have NFT multiplier
   *
   * @param _pid  id of the pool
   * @param _addr address of the user
   *
   * @return multi Value of multiplier
   *
   */

  function calcMultiplier(uint256 _pid, address _addr) public view override returns (uint16 multi) {
    NFTMultiplier memory nft = nftInfo[_pid];

    if (nft.active && ownsCorrectNFT(_addr, _pid) && _addr != compounderContract) {
      multi = nft.multiplier;
    } else {
      multi = 10;
    }
  }

  function ownsCorrectNFT(address _addr, uint256 _pid) public view returns (bool) {
    NFTMultiplier memory nft = nftInfo[_pid];

    uint256[] memory ids = walletOfOwner(nft.contractAdd, _addr);
    for (uint256 i = 0; i < ids.length; i++) {
      if (ids[i] >= nft.startIdx && ids[i] <= nft.endIdx) {
        return true;
      }
    }
    return false;
  }

  function payout(uint256 _pid, address _addr) public view override returns (uint256 value) {
    User storage user = users[_pid][_addr];
    Pool storage pool = poolInfo[_pid];

    uint256 from = user.lastPayout > user.depositTime ? user.lastPayout : user.depositTime;
    uint256 to = block.timestamp > pool.endDate ? pool.endDate : block.timestamp;

    uint256 multiplier = calcMultiplier(_pid, _addr);

    if (from < to) {
      uint256 rayValue = yearlyRateToRay((pool.apy * 10 ** 18) / 1000);
      value = (accrueInterest(user.totalInvested, rayValue, to.sub(from))).sub(user.totalInvested);
    }

    value = value.mul(multiplier).div(10);

    return value;
  }

  /**
   *
   * @dev get length of the pools
   *
   * @return {uint256} length of the pools
   *
   */
  function poolLength() public view override returns (uint256) {
    return poolInfo.length;
  }

  /**
   *
   * @dev get info of all pools
   *
   * @return {PoolInfo[]} Pool info struct
   *
   */
  function getPools() public view returns (Pool[] memory) {
    return poolInfo;
  }

  /**
   *
   * @dev safe TOKEN transfer function, require to have enough TOKEN to transfer
   *
   */
  function safeTOKENTransfer(address _token, address _to, uint256 _amount) internal {
    IERC20Upgradeable token = IERC20Upgradeable(_token);
    uint256 bal = token.balanceOf(address(this));

    require(bal >= _amount, "Not enough funds in treasury");

    uint256 maxTx = maxTransferAmount[_token];
    uint256 amount = _amount;

    while (amount > maxTx) {
      token.transfer(_to, maxTx);
      amount = amount - maxTx;
    }

    if (amount > 0) {
      token.transfer(_to, amount);
    }
  }

  function _claim(uint256 _pid, address _addr) internal {
    User storage user = users[_pid][_addr];
    Pool memory pool = poolInfo[_pid];

    uint256 amount = payout(_pid, _addr);

    if (amount > 0) {
      user.totalWithdrawn = user.totalWithdrawn.add(amount);

      uint256 feeAmount = amount.mul(feePercent).div(1000);

      safeTOKENTransfer(pool.token, feeAddress, feeAmount);

      amount = amount.sub(feeAmount);

      safeTOKENTransfer(pool.token, _addr, amount);

      user.lastPayout = block.timestamp;

      user.totalClaimed = user.totalClaimed.add(amount);
    }

    emit Claim(_addr, amount, block.timestamp);
  }

  function _stake(uint256 _pid, address _sender, uint256 _amount, bool _isReinvest) internal {
    User storage user = users[_pid][_sender];
    Pool storage pool = poolInfo[_pid];

    if (!_isReinvest || _sender != compounderContract) {
      user.depositTime = block.timestamp;
      if (_sender != compounderContract) {
        require(pool.totalDeposit.add(_amount) <= pool.hardCap, "Pool is full");
        uint256 stopDepo = pool.endDate.sub(pool.lockPeriodInDays.mul(1 days));
        require(block.timestamp <= stopDepo, "Staking is disabled for this pool");
      }
    }

    user.totalInvested = user.totalInvested.add(_amount);
    pool.totalDeposit = pool.totalDeposit.add(_amount);
    user.lastPayout = block.timestamp;

    emit Stake(_sender, _amount, block.timestamp);
  }

  /**
   *
   *
   * @dev Fetching nfts owned by a user
   *
   */
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
}
