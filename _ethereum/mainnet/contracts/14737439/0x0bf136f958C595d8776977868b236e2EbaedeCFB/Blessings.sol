// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.7;

/// ============ Imports ============

import "./ISwapRouter.sol";
import "./IEggs.sol";
import "./ERC20.sol";
import "./AccessControl.sol";
import "./ReentrancyGuard.sol";
import "./IERC721Enumerable.sol";

/// @title Blessings
/// @notice allows claimable CHURCH and BLESSINGS reward cycles for liquidity stakers

contract Blessings is AccessControl, ReentrancyGuard, ERC20 {
  bytes32 public constant DEPLOYER_ROLE = keccak256("DEPLOYER_ROLE");
  bytes32 public constant REWARDER_ROLE = keccak256("REWARDER_ROLE");

  uint256 public currentCycle;

  mapping(uint256 => RewardData) public rewards;
  mapping(address => UserPosition) public _userPositions;
  mapping(address => uint256) public liquidityLocked;
  uint256 public _cumulativeRewardSupply;

  /* Events */
  event BlessEggs(address blesser, address user, uint256 amount);
  event Withdrawl(address user, uint256 amount);
  event Deposit(address user, uint256 amount);
  event AddReward(uint256 amount);
  event Claim(address user);

  IEggs public _Eggs;

  IERC20 public immutable _CHURCH = IERC20(0x71018cc3D0CCdc7E10C48550554cE4D4E3afd9C1);
  address public routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
  address public rewarderWallet;
  IERC20 public _LPToken;

  bool public frozen;

  uint256 private immutable percision = 100000000;

  struct UserPosition {
    uint256 blessingsClaimedAt;
    uint256 entryCycle;
    uint256 shares;
  }

  struct RewardData {
    uint256 totalShares;
    uint256 rewardAmount;
  }

  constructor(address lpAddress, address _rewarderWallet, address eggAddress) ERC20("Blessed By $CHURCH", "BLESSINGS") {
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(REWARDER_ROLE, _rewarderWallet);
    _grantRole(DEPLOYER_ROLE, msg.sender);

    _Eggs = IEggs(eggAddress);
    rewarderWallet = _rewarderWallet;
    _LPToken = IERC20(lpAddress);
  }

  // Return info about blessings and staked LP to web3
  function getInfo(address user) external view returns (uint256[] memory) {
    uint256[] memory info = new uint256[](14);
    info[0] = _LPToken.balanceOf(user);
    info[1] = _LPToken.allowance(user, address(this));
    info[2] = amountLocked(user); // user's staked LP
    info[3] = rewards[currentCycle].totalShares; // total LP staked
    info[4] = blessingsToClaimForUser(user);
    info[5] = balanceOf(user); // Blessings balance
    info[6] = _CHURCH.balanceOf(user); // Blessings balance
    info[7] = _CHURCH.balanceOf(address(_LPToken)); // amount of CHURCH in the LP reserves
    info[8] = _LPToken.totalSupply(); // total LP tokens
    info[9] = _CHURCH.balanceOf(address(rewarderWallet)); // remaining rewards
    info[10] = churchPerETH();
    if (user != address(0)) {
      info[11] = _Eggs.balanceOf(user);
      info[12] = _Eggs.userBlessings(user);
    }
    info[13] = _Eggs.totalBlessings();

    return info;
  }

  function amountLocked(address user) public view returns (uint256) {
    return _userPositions[user].shares;
  }

  function amountsToClaim() external view returns (uint256[] memory) {
    return amountsToClaimForUser(msg.sender);
  }

  function amountsToClaimForUser(address user) public view returns (uint256[] memory) {
    uint256[] memory info = new uint256[](2);

    info[0] = churchToClaimForUser(user);
    info[1] = blessingsToClaimForUser(user);

    return info;
  }

  function amountToClaimForCycle(UserPosition memory position, uint256 cycleIndex, uint256 currentChurchSupply) internal view returns (uint256){
    if (cycleIndex < position.entryCycle) return 0;
    if (cycleIndex >= currentCycle) return 0;

    RewardData memory reward = rewards[cycleIndex];
    if (reward.totalShares == 0) return 0;

    uint256 poolRatio = percision * reward.rewardAmount / _cumulativeRewardSupply;
    uint256 ownershipRatio = percision * position.shares / reward.totalShares;
    uint256 ownership = ownershipRatio * poolRatio * currentChurchSupply / (percision * percision);

    return ownership;
  }

  // Fetch price of CHURCH
  function churchPerETH() public view returns (uint256){
    address[] memory path = new address[](2);
    path[0] = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    path[1] = address(_CHURCH);

    uint256[] memory amountsOut = ISwapRouter(routerAddress).getAmountsOut(10**18, path);
    return amountsOut[1];
  }

  function depositLiquidity(uint256 amount) external nonReentrant {
    if (!hasRole(DEPLOYER_ROLE, msg.sender))
      require(block.timestamp > 1652102227, "Not yet enabled");

    liquidityLocked[msg.sender] = block.timestamp;
    _LPToken.transferFrom(msg.sender, address(this), amount);

    _claim();

    rewards[currentCycle].totalShares += amount;
    _userPositions[msg.sender].shares += amount;

    emit Deposit(msg.sender, amount);
  }

  function withdrawLiquidity(uint256 amount) external nonReentrant {
    require((liquidityLocked[msg.sender] + 7 days) < block.timestamp, 'your liquidity is locked');

    rewards[currentCycle].totalShares -= amount;

    UserPosition storage position = _userPositions[msg.sender];
    require(position.shares >= amount, 'Can not withdraw this amount');

    _claim();

    _LPToken.transfer(msg.sender, amount);
    _userPositions[msg.sender].shares -= amount;

    emit Withdrawl(msg.sender, amount);
  }

  function blessEggs(address user, uint256 amount) external nonReentrant {
    require(balanceOf(msg.sender) >= amount, 'You do not have enough BLESSINGS');
    _burn(msg.sender, amount);
    _Eggs.blessEggs(user, amount);

    emit BlessEggs(msg.sender, user, amount);
  }

  function addReward(uint256 rewardAmount) external onlyRole(REWARDER_ROLE) {
    require(rewardAmount > 0, 'Reward amount can not be zero');
    RewardData storage reward = rewards[currentCycle];
    reward.rewardAmount = rewardAmount;

    currentCycle += 1;
    rewards[currentCycle].totalShares = reward.totalShares;

    _cumulativeRewardSupply += rewardAmount;
    _CHURCH.transferFrom(msg.sender, address(this), rewardAmount);

    emit AddReward(rewardAmount);
  }

  function claim() external nonReentrant {
    _claim();
  }

  function _claim() internal {
    require(!frozen, 'rewards are frozen');
    UserPosition storage position = _userPositions[msg.sender];

    uint256 toClaim = churchToClaimForPosition(position);
    if (toClaim > 0) _CHURCH.transfer(msg.sender, toClaim);
    _mint(msg.sender, blessingsToClaimForPosition(position));

    position.entryCycle = currentCycle;
    position.blessingsClaimedAt = block.number;
  }

  function churchToClaim() public view returns (uint256) {
    return churchToClaimForUser(msg.sender);
  }

  function churchToClaimForUser(address user) public view returns (uint256) {
    UserPosition memory position = _userPositions[user];
    return churchToClaimForPosition(position);
  }

  function churchToClaimForPosition(UserPosition memory position) internal view returns (uint256) {
    uint256 toClaim;

    uint256 currentChurchSupply = _CHURCH.balanceOf(address(this));
    for(uint256 cycleIndex = position.entryCycle; cycleIndex < currentCycle; cycleIndex++)
      toClaim += amountToClaimForCycle(position, cycleIndex, currentChurchSupply);

    return toClaim;
  }

  function blessingsToClaim() public view returns (uint256) {
    return blessingsToClaimForUser(msg.sender);
  }

  function blessingsToClaimForUser(address user) public view returns (uint256) {
    UserPosition memory position = _userPositions[user];
    return blessingsToClaimForPosition(position);
  }

  function blessingsToClaimForPosition(UserPosition memory position) internal view returns (uint256) {
    return position.shares * (block.number - position.blessingsClaimedAt) / 1000;
  }

  function toggleFrozen() public onlyRole(DEPLOYER_ROLE) {
    frozen = !frozen;
  }

  function setRewarderWallet(address addr) public onlyRole(DEPLOYER_ROLE) {
    rewarderWallet = addr;
  }

}
