// SPDX-License-Identifier: Apache-2.0-with-puul-exception
pragma solidity >=0.6.12;
import "./Arrays.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./SafeCast.sol";
import "./Console.sol";
import "./ERC20.sol";
import "./Fees.sol";
import "./IFarm.sol";
import "./IPoolFarm.sol";
import "./PuulRewards.sol";
import "./Limits.sol";

contract EarnPool is ERC20, ReentrancyGuard, PuulRewards, IPoolFarm {
  using Address for address;
  using SafeMath for uint256;
  using Arrays for uint256[];
  using SafeERC20 for IERC20;

  Fees _fees;
  Limits _limits;
  mapping (IERC20 => uint256) _rewardExtra;
  mapping (IERC20 => uint256) _accSharePrices;
  mapping (address => mapping (IERC20 => uint256)) _owedRewards;
  mapping (address => mapping (IERC20 => uint256)) _debtSharePrices;

  bool _allowAll;
  bool _initialized;

  uint256 precision = 1e18;
  uint256 constant MIN_PRICE_PER_SHARE = 10;

  modifier onlyMember() {
    isMember(msg.sender);
    _;
  }

  modifier onlyWithdrawal() {
    require((address(_fees) != address(0) && msg.sender == _fees.withdrawal()), '!with');
    _;
  }

  function isMember(address member) internal view {
    require(member != address(0) && (_allowAll == true || hasRole(ROLE_MEMBER, member)), '!mem');
  }

  constructor (string memory name, string memory symbol, bool allowAll, address fees) public ERC20(name, symbol) {
    if (fees != address(0))
      _fees = Fees(fees);
    _allowAll = allowAll;
    _setupRole(ROLE_ADMIN, msg.sender);
    _setupRole(ROLE_HARVESTER, msg.sender);
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  function setupRoles(address defaultAdmin, address admin, address extract, address harvester, address minter) onlyDefaultAdmin external {
    _setupRoles(defaultAdmin, admin, extract, harvester, minter);
  }

  function _setupRoles(address defaultAdmin, address admin, address extract, address harvester, address minter) internal {
    _setup(ROLE_EXTRACT, extract);
    _setup(ROLE_MINTER, minter);
    _setup(ROLE_HARVESTER, harvester);
    _setupAdmin(admin);
    _setupDefaultAdmin(defaultAdmin);
  }

  function mint(address to, uint256 amount) external onlyMinter {
    _mint(to, amount);
  }

  function addMember(address member) onlyAdmin external {
    _setupRole(ROLE_MEMBER, member);
  }

  function getFees() external view returns(address) {
    return address(_fees);
  }

  function setFees(address fees) onlyMinter external {
    _fees = Fees(fees);
  }

  function setLimits(address limits) onlyAdmin external {
    _limits = Limits(limits);
  }

  function getLimits() external view returns(address) {
    return address(_limits);
  }

  function initialize() onlyAdmin nonReentrant external returns(bool success) {
    if (_initialized) return false;
    _initialized = _initialize();
    return _initialized;
  }

  function _initialize() virtual internal returns(bool) {
    return true;
  }

  function earn() onlyHarvester nonReentrant virtual external {
    _earn();
  }

  function unearn() onlyHarvester nonReentrant virtual external {}

  function harvest() onlyHarvester nonReentrant virtual external {
    _harvest();
    _earn();
  }

  function harvestOnly() onlyHarvester nonReentrant virtual external {
    _harvest();
  }

  function _earn() virtual internal { }
  function _unearn(uint256 amount) virtual internal { }

  /* Trying out function parameters for a functional map */
  function mapToken(IERC20[] storage self, function (IERC20) view returns (uint256) f) internal view returns (uint256[] memory r) {
    uint256 len = self.length;
    r = new uint[](len);
    for (uint i = 0; i < len; i++) {
      r[i] = f(self[i]);
    }
  }

  function balanceOfToken(IERC20 token) internal view returns (uint256) {
    return token.balanceOf(address(this));
  }

  function _harvest() internal virtual {
    uint256[] memory prev = mapToken(_rewards, balanceOfToken);
    _harvestRewards();
    for (uint256 i = 0; i < _rewards.length; i++) {
      IERC20 token = _rewards[i];
      uint256 tokenSupply = token.balanceOf(address(this)).sub(prev[i], 'tokenSupply<0');
      _rewardTotals[token] = _rewardTotals[token].add(tokenSupply);
      _updateRewardSharePrice(token, tokenSupply);
    }
  }

  function _updateRewardSharePrice(IERC20 token, uint256 tokenSupply) internal {
    uint256 supply = totalSupply();
    uint256 extra = _rewardExtra[token];
    if (extra > 0) {
      tokenSupply = tokenSupply.add(extra);
      _rewardExtra[token] = 0;
    }
    if (tokenSupply == 0) return; // Nothing to do
    uint256 pricePerShare = supply > 0 ? (tokenSupply * precision).div(supply) : 0;
    if (pricePerShare < MIN_PRICE_PER_SHARE) {
      pricePerShare = 0;
    }
    _accSharePrices[token] = pricePerShare.add(_accSharePrices[token]);
    if (pricePerShare == 0) {
      _rewardExtra[token] = tokenSupply.add(_rewardExtra[token]);
    } else {
      uint256 rounded = pricePerShare.mul(supply).div(precision);
      if (rounded < tokenSupply) {
        _rewardExtra[token] = _rewardExtra[token].add(tokenSupply - rounded);
      }
    }
  }

  function owedRewards() external view returns(uint256[] memory rewards) {
    rewards = new uint256[](_rewards.length);
    mapping (IERC20 => uint256) storage owed = _owedRewards[msg.sender];
    for (uint256 i = 0; i < _rewards.length; i++) {
      IERC20 token = _rewards[i];
      rewards[i] = owed[token];
    }
  }

  function getPendingRewards(address sender) onlyHarvester external view returns(uint256[] memory totals) {
    totals = _pendingRewards(sender);
  }

  function pendingRewards() external view returns(uint256[] memory totals) {
    totals = _pendingRewards(msg.sender);
  }

  function _pendingRewards(address sender) internal view returns(uint256[] memory totals) {
    uint256 amount = balanceOf(sender);
    totals = new uint256[](_rewards.length);
    mapping (IERC20 => uint256) storage owed = _owedRewards[sender];
    for (uint256 i = 0; i < _rewards.length; i++) {
      totals[i] = owed[_rewards[i]];
    }
    mapping (IERC20 => uint256) storage debt = _debtSharePrices[sender];
    for (uint256 i = 0; i < _rewards.length; i++) {
      IERC20 token = _rewards[i];
      uint256 debtSharePrice = debt[token];
      uint256 currentSharePrice = _accSharePrices[token];
      totals[i] += ((currentSharePrice - debtSharePrice) * amount).div(precision);
    }
  }

  function addReward(address token) onlyAdmin external override virtual {
    if (_addReward(token)) {
      uint256 tokenSupply = IERC20(token).balanceOf(address(this));
      _updateRewardSharePrice(IERC20(token), tokenSupply);
    }
  }

  function rewardAdded(address token) onlyFarm external override virtual {
    if (_addReward(token)) {
      uint256 tokenSupply = IERC20(token).balanceOf(address(this));
      _updateRewardSharePrice(IERC20(token), tokenSupply);
    }
  }

  event Deposit(address, uint);
  function _deposit(uint256 amount) internal virtual {
    if (address(_limits) != address(0)) 
      _limits.checkLimits(msg.sender, address(this), amount);
    _mint(msg.sender, amount);
    emit Deposit(msg.sender, amount);
  }

  function _updateRewards(address user, uint256 amount, bool updateDebt) internal {
    mapping (IERC20 => uint256) storage owed = _owedRewards[user];
    mapping (IERC20 => uint256) storage debt = _debtSharePrices[user];
    for (uint256 i = 0; i < _rewards.length; i++) {
      IERC20 token = _rewards[i];
      uint256 debtSharePrice = debt[token];
      uint256 currentSharePrice = _accSharePrices[token];
      uint256 computedSharePrice = currentSharePrice - debtSharePrice;
      if (computedSharePrice > 0) {
        uint256 rewards = computedSharePrice.mul(amount).div(precision);
        owed[token] = rewards.add(owed[token]);
      }
      if (updateDebt) {
        debt[token] = currentSharePrice;
      }
    }
  }

  function _splitWithdrawal(uint256 amount, address account) internal view returns(uint256 newAmount, uint256 feeAmount, address withdrawal) {
    withdrawal = address(_fees) == address(0) ? address(0) : _fees.withdrawal();
    if (withdrawal == account) // no fees for withdrawer
      withdrawal = address(0);
    feeAmount = withdrawal == address(0) ? 0 : _fees.withdrawalFee(amount);
    newAmount = amount - feeAmount;
  }

  function _mint(address account, uint256 amount) internal override {
    isMember(account);
    uint256 balance = _balances[account];
    _updateRewards(account, balance, true);

    _totalSupply = _totalSupply.add(amount);
    _balances[account] = balance.add(amount);
    emit Transfer(address(0), account, amount);
  }

  function _burn(address account, uint256 amount) internal override {
    isMember(account);
    _updateRewards(account, amount, false);

    _balances[account] = _balances[account].sub(amount, "burn amount");
    _totalSupply = _totalSupply.sub(amount);
    emit Transfer(account, address(0), amount);
  }

  function _burnWithFee(address account, uint256 amount) internal returns (uint256) {
    isMember(account);
    _updateRewards(account, amount, false);

    (uint256 newAmount, uint256 feeAmount, address withdrawal) = _splitWithdrawal(amount, account);
    require(newAmount + feeAmount == amount, 'bad amount');

    if (withdrawal != address(0))
      _updateRewards(withdrawal, _balances[withdrawal], true);

    _balances[account] = _balances[account].sub(amount, "burn amount");
    if (withdrawal != address(0))
      _balances[withdrawal] = _balances[withdrawal].add(feeAmount);
    _totalSupply = _totalSupply.sub(newAmount);

    if (withdrawal != address(0))
      emit Transfer(address(0), withdrawal, feeAmount);
    emit Transfer(account, address(0), amount);

    return newAmount;
  }

  function _transfer(address sender, address recipient, uint256 amount) internal override {
    isMember(sender);
    isMember(recipient);
    _updateRewards(sender, amount, false);

    (uint256 newAmount, uint256 feeAmount, address withdrawal) = _splitWithdrawal(amount, sender);
    require(newAmount + feeAmount == amount, 'xfer amt');
    _updateRewards(recipient, _balances[recipient], true);
    
    if (withdrawal != address(0)) {
      _updateRewards(withdrawal, _balances[withdrawal], true);
      _balances[withdrawal] = _balances[withdrawal].add(feeAmount);
    }
    _balances[recipient] = _balances[recipient].add(newAmount);
    _balances[sender] = _balances[sender].sub(amount, "xfer amt");

    emit Transfer(sender, recipient, newAmount);
    if (withdrawal != address(0))
      emit Transfer(sender, withdrawal, feeAmount);
  }

  function _harvestRewards() virtual internal { }

  function updateRewards() nonReentrant external {
    _updateRewards(msg.sender, balanceOf(msg.sender), true);
  }

  function updateAndClaim() nonReentrant external override {
    _updateRewards(msg.sender, balanceOf(msg.sender), true);
    _claim();
  }

  function claim() nonReentrant external override {
    _claim();
  }

  function _claim() internal virtual {
    mapping (IERC20 => uint256) storage owed = _owedRewards[msg.sender];
    for (uint256 i = 0; i < _rewards.length; i++) {
      IERC20 token = _rewards[i];
      uint256 amount = owed[token];
      owed[token] = 0;
      safeTransferReward(token, msg.sender, amount);
    }
  }

  event Withdraw(address, uint);
  function withdrawAll() nonReentrant external virtual {
    _withdraw(balanceOf(msg.sender));
  }

  function withdraw(uint256 amount) nonReentrant external virtual {
    require(amount <= balanceOf(msg.sender));
    _withdraw(amount);
  }

  function withdrawFees() onlyWithdrawal nonReentrant virtual external {
    _withdrawFees();
  }

  function _withdrawFees() virtual internal returns(uint256 amount) {
    require(address(_fees) != address(0));
    address withdrawer = _fees.withdrawal();
    amount = balanceOf(withdrawer);
    _unearn(amount);
    _burn(withdrawer, amount);
  }

  function _withdraw(uint256 amount) virtual internal returns(uint256 afterFee) {
    afterFee = _burnWithFee(msg.sender, amount);
    _unearn(afterFee);
  }

  function _tokenInUse(address token) override virtual internal view returns(bool) {
    return PuulRewards._tokenInUse(token);
  }

}
