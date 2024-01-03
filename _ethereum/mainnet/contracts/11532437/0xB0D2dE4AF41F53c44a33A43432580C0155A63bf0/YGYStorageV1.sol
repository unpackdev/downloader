// SPDX-License-Identifier: UNLICENSED;
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

/**
Storage contract for the YGY system
*/
import "./SafeMath.sol";
import "./AccessControl.sol";
import "./IERC20.sol";
import "./INBUNIERC20.sol";
import "./IWETH.sol";
import "./PoolHelper.sol";


contract YGYStorageV1 is AccessControlUpgradeSafe {
  /* STORAGE CONFIG */
  using SafeMath for uint256;
  using PoolHelper for PoolInfo;

  bytes32 public constant MODIFIER_ROLE = keccak256("MODIFIER_ROLE");

  function setModifierContracts(
    address _vault,
    address _router,
    address _nftFactory
  ) external {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Nono");
    _setupRole(MODIFIER_ROLE, _vault);
    _setupRole(MODIFIER_ROLE, _router);
    _setupRole(MODIFIER_ROLE, _nftFactory);
  }

  function init() external initializer {
    __AccessControl_init();
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _setupRole(MODIFIER_ROLE, _msgSender());
  }

  /* RAMVAULT */

  // User properties per vault/pool.
  struct UserInfo {
    uint256 amount; // How many  tokens the user has provided.
    uint256 rewardDebt; // Reward debt. See explanation below.
    uint256 rewardDebtYGY;
    uint256 boostAmount;
    uint256 boostLevel;
    uint256 spentMultiplierTokens;
  }

  struct NFTUsage {
    uint256 contractId;
    uint256 epoch;
  }

  // Epoch -> User -> NFT ids in use.
  mapping(uint256 => mapping(address => NFTUsage[])) public NFTUsageInfo;

  function setNFTInUse(uint256 _contractId, address _user) external {
    require(hasRole(MODIFIER_ROLE, _msgSender()));
    NFTUsageInfo[epoch][_user].push(NFTUsage({ contractId: _contractId, epoch: epoch }));
  }

  function getNFTsInUse(address _user) external view returns (NFTUsage[] memory) {
    return NFTUsageInfo[epoch][_user];
  }

  function getNFTBoost(address _user) external view returns (uint256) {
    uint256 NFTBoost;
    NFTUsage[] memory nftInfo = NFTUsageInfo[epoch][_user];
    for (uint256 i; i < nftInfo.length; i++) {
      if (epoch == nftInfo[i].epoch) {
        if (nftInfo[i].contractId == 5 || nftInfo[i].contractId == 6) {
          NFTBoost = NFTBoost.add(10);
        }
      }
    }
    return NFTBoost;
  }

  // Pool/Vault/Whatever-id -> userrAddress -> userInfo
  mapping(uint256 => mapping(address => UserInfo)) public userInfo;

  function updateUserInfo(
    uint256 _poolId,
    address _userAddress,
    UserInfo memory _userInfo
  ) external {
    require(hasRole(MODIFIER_ROLE, _msgSender()));
    userInfo[_poolId][_userAddress] = _userInfo;
  }

  // PoolId -> UserAddress -> Spender -> Allowance
  mapping(uint256 => mapping(address => mapping(address => uint256))) public poolAllowance;

  function setPoolAllowance(
    uint256 _pid,
    address _user,
    address _spender,
    uint256 _allowance
  ) external {
    require(hasRole(MODIFIER_ROLE, _msgSender()));
    poolAllowance[_pid][_user][_spender] = _allowance;
  }

  // Pool properties
  struct PoolInfo {
    IERC20 token; // Address of  token contract.
    uint256 allocPoint; // How many allocation points assigned to this pool. RAMs to distribute per block.
    uint256 accRAMPerShare; // Accumulated RAMs per share, times 1e12. See below.
    uint256 accYGYPerShare; // Accumulated YGYs per share, times 1e12. See below.
    bool withdrawable; // Is this pool withdrawable?
    uint256 effectiveAdditionalTokensFromBoosts; // Track the total additional accounting staked tokens from boosts.
  }
  // All pool properties
  PoolInfo[] public poolInfo;

  function updatePoolInfo(uint256 _poolId, PoolInfo memory _userInfo) external {
    require(hasRole(MODIFIER_ROLE, _msgSender()));
    poolInfo[_poolId] = _userInfo;
  }

  function setPool(
    uint256 _poolId,
    uint256 _allocPoint,
    bool _withdrawable
  ) external {
    require(hasRole(MODIFIER_ROLE, _msgSender()));
    totalAllocPoint.sub(poolInfo[_poolId].allocPoint).add(_allocPoint);
    poolInfo[_poolId].allocPoint = _allocPoint;
    poolInfo[_poolId].withdrawable = _withdrawable;
  }

  function addPool(
    uint256 _allocPoint,
    IERC20 _token,
    bool _withdrawable
  ) external {
    require(hasRole(MODIFIER_ROLE, _msgSender()));
    for (uint256 pid = 0; pid < poolInfo.length; ++pid) {
      require(poolInfo[pid].token != _token, "Error pool already added");
    }
    totalAllocPoint = totalAllocPoint.add(_allocPoint);
    poolInfo.push(
      YGYStorageV1.PoolInfo({
        token: _token,
        allocPoint: _allocPoint,
        accRAMPerShare: 0,
        accYGYPerShare: 0,
        withdrawable: _withdrawable,
        effectiveAdditionalTokensFromBoosts: 0
      })
    );
  }

  function updatePoolRewards(uint256 allRewards, uint256 allYGYRewards) external {
    require(hasRole(MODIFIER_ROLE, _msgSender()));
    pendingRewards = pendingRewards.sub(allRewards);
    pendingYGYRewards = pendingYGYRewards.sub(allYGYRewards);
  }

  function addPendingRewards(uint256 _amount) external {
    require(hasRole(MODIFIER_ROLE, _msgSender()), "Prohibited caller");
    pendingRewards = pendingRewards.add(_amount);
    rewardsInThisEpoch = rewardsInThisEpoch.add(_amount);

    if (YGYReserve > _amount) {
      pendingYGYRewards = pendingYGYRewards.add(_amount);
      YGYRewardsInThisEpoch = YGYRewardsInThisEpoch.add(_amount);
      YGYReserve = YGYReserve.sub(_amount);
    } else if (YGYReserve > 0) {
      YGYRewardsInThisEpoch = YGYRewardsInThisEpoch.add(_amount);
      pendingYGYRewards = pendingYGYRewards.add(YGYReserve);
      YGYReserve = 0;
    }
  }

  function addAdditionalRewards(uint256 _amount, bool _ygy) external {
    require(hasRole(MODIFIER_ROLE, _msgSender()));
    if (_ygy) {
      YGYReserve = YGYReserve.add(_amount);
    } else {
      pendingRewards = pendingRewards.add(_amount);
      rewardsInThisEpoch = rewardsInThisEpoch.add(_amount);
    }
  }

  function getPoolLength() external view returns (uint256) {
    return poolInfo.length;
  }

  function getPoolInfo(uint256 _poolId)
    external
    view
    returns (
      IERC20 _token,
      uint256 _allocPointt,
      uint256 _accRAMPerShare,
      uint256 _accYGYPerShare,
      bool _withdrawable,
      uint256 _effectiveAdditionalTokensFromBoosts
    )
  {
    PoolInfo memory pool = poolInfo[_poolId];
    return (
      pool.token,
      pool.allocPoint,
      pool.accRAMPerShare,
      pool.accYGYPerShare,
      pool.withdrawable,
      pool.effectiveAdditionalTokensFromBoosts
    );
  }

  // Total allocattion points for the whole contract
  uint256 public totalAllocPoint;

  // Pending rewards.
  uint256 public pendingRewards;
  uint256 public pendingYGYRewards;

  // Extra balance-keeping for extra-token rewards
  uint256 public YGYReserve;

  function setYGYReserve(uint256 _amount) external {
    require(hasRole(MODIFIER_ROLE, _msgSender()));
    YGYReserve = _amount;
  }

  // Reward token balance-keeping
  uint256 internal ramBalance;

  function setRAMBalance(uint256 _amount) external {
    require(hasRole(MODIFIER_ROLE, _msgSender()));
    ramBalance = _amount;
  }

  uint256 internal ygyBalance;

  function setYGYBalance(uint256 _amount) external {
    require(hasRole(MODIFIER_ROLE, _msgSender()));
    ygyBalance = _amount;
  }

  uint256 public RAMVaultStartBlock;

  function setRAMVaultStartBlock() external {
    require(hasRole(MODIFIER_ROLE, _msgSender()));
    RAMVaultStartBlock = block.number;
  }

  uint256 public epochStartBlock;

  function setEpochCalculationStartBlock() external {
    require(hasRole(MODIFIER_ROLE, _msgSender()));
    epochStartBlock = block.number;
  }

  uint256 public cumulativeRewardsSinceStart;
  uint256 public cumulativeYGYRewardsSinceStart;

  function setCumulativeRewardsSinceStart() external {
    require(hasRole(MODIFIER_ROLE, _msgSender()));
    cumulativeRewardsSinceStart = cumulativeRewardsSinceStart + rewardsInThisEpoch;
    cumulativeYGYRewardsSinceStart = cumulativeYGYRewardsSinceStart + YGYRewardsInThisEpoch;
  }

  uint256 public rewardsInThisEpoch;
  uint256 public YGYRewardsInThisEpoch;

  function setRewardsInThisEpoch(uint256 _amount, uint256 _ygyAmount) external {
    require(hasRole(MODIFIER_ROLE, _msgSender()));
    rewardsInThisEpoch = _amount;
    YGYRewardsInThisEpoch = _ygyAmount;
  }

  uint256 public epoch;

  // TOKENS
  INBUNIERC20 public ram; // The RAM token
  IERC20 public ygy; // The YGY token
  address public _YGYRAMPair;
  address public _YGYToken;
  address public _YGYWETHPair;
  address public _RAMToken;
  IWETH public _WETH;
  IERC20 public _dXIOTToken;

  function initializeRAMVault() external {
    require(hasRole(MODIFIER_ROLE, _msgSender()) || hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Prohibited caller");
    RAMVaultStartBlock = block.number;
    epochStartBlock = block.number;

    boostLevelCosts[1] = 5 * 1e18; // 5 RAM tokens
    boostLevelCosts[2] = 15 * 1e18; // 15 RAM tokens
    boostLevelCosts[3] = 30 * 1e18; // 30 RAM tokens
    boostLevelCosts[4] = 60 * 1e18; // 60 RAM tokens
    boostLevelMultipliers[1] = 5; // 5%
    boostLevelMultipliers[2] = 15; // 15%
    boostLevelMultipliers[3] = 30; // 30%
    boostLevelMultipliers[4] = 60; // 60%
  }

  function setTokens(
    address RAMToken,
    address YGYToken,
    address WETH,
    address YGYRAMPair,
    address YGYWethPair,
    address[] memory nfts,
    address dXIOTToken
  ) external {
    require(hasRole(MODIFIER_ROLE, _msgSender()) || hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Prohibited caller");
    ram = INBUNIERC20(RAMToken);
    ygy = IERC20(YGYToken);
    _RAMToken = RAMToken;
    _YGYToken = YGYToken;
    _WETH = IWETH(WETH);
    _YGYRAMPair = YGYRAMPair;
    _YGYWETHPair = YGYWethPair;
    _dXIOTToken = IERC20(dXIOTToken);
    for (uint256 i = 0; i < nfts.length; i++) {
      _NFTs[i + 1] = nfts[i];
    }
  }

  // Boosts
  uint256 public boostFees;

  function setBoostFees(uint256 _amount, bool _add) external {
    require(hasRole(MODIFIER_ROLE, _msgSender()));
    if (_add) {
      boostFees = boostFees.add(_amount);
    } else {
      boostFees = _amount;
    }
  }

  mapping(uint256 => uint256) public boostLevelCosts;

  function checkRewards(uint256 _pid, address _user) external view returns (uint256 pendingRAM, uint256 pendingYGY) {
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][_user];

    uint256 effectiveAmount = user.amount.add(user.boostAmount);
    uint256 YGYRewards;
    if (pool.accYGYPerShare > 0) {
      YGYRewards = effectiveAmount.mul(pool.accYGYPerShare).div(1e12).sub(user.rewardDebtYGY);
    }
    return (effectiveAmount.mul(pool.accRAMPerShare).div(1e12).sub(user.rewardDebt), YGYRewards);
  }

  function getBoostLevelCost(uint256 _level) external view returns (uint256) {
    return boostLevelCosts[_level];
  }

  mapping(uint256 => uint256) public boostLevelMultipliers;

  function getBoostLevelMultiplier(uint256 _level) external view returns (uint256) {
    return boostLevelMultipliers[_level];
  }

  function updateBoosts(uint256[] memory _boostMultipliers, uint256[] memory _boostCosts) external {
    require(hasRole(MODIFIER_ROLE, _msgSender()));
    // Update boost costs
    for (uint8 i; i <= _boostMultipliers.length; i++) {
      boostLevelCosts[i + 1] = _boostCosts[i];
      boostLevelMultipliers[i + 1] = _boostMultipliers[i];
    }
  }

  // For easy graphing historical epoch rewards
  mapping(uint256 => uint256) public epochRewards;

  function setEpochRewards() external {
    require(hasRole(MODIFIER_ROLE, _msgSender()));
    epochRewards[epoch] = rewardsInThisEpoch;
    epoch++;
  }

  function averageFeesPerBlockSinceStart() external view returns (uint256 averagePerBlock, uint256 ygyPerBlock) {
    return (
      cumulativeRewardsSinceStart.add(rewardsInThisEpoch).div(block.number.sub(RAMVaultStartBlock)),
      cumulativeYGYRewardsSinceStart.add(YGYRewardsInThisEpoch).div(block.number.sub(RAMVaultStartBlock))
    );
  }

  // Returns averge fees in this epoch
  function averageFeesPerBlockEpoch() external view returns (uint256 averagePerBlock, uint256 ygyPerBlock) {
    return (rewardsInThisEpoch.div(block.number.sub(epochStartBlock)), YGYRewardsInThisEpoch.div(block.number.sub(epochStartBlock)));
  }

  /*
         ROUTER
    */

  // Mapping of (user => last ticket level)
  mapping(address => uint256) public lastTicketLevel;

  // Setter for contracts using
  function setLastTicketLevel(address _user, uint256 _level) external {
    require(hasRole(MODIFIER_ROLE, _msgSender()));
    lastTicketLevel[_user] = _level;
  }

  // Total eth contributed to a vault.
  mapping(address => uint256) public liquidityContributedEthValue;

  // Set value for mapping from external contracts
  function setLiquidityContributedEthValue(
    address _spender,
    uint256 _amount,
    bool _delete
  ) external {
    require(hasRole(MODIFIER_ROLE, _msgSender()));
    if (_delete) {
      delete liquidityContributedEthValue[_spender];
    } else {
      liquidityContributedEthValue[_spender] = liquidityContributedEthValue[_spender].add(_amount);
    }
  }

  // NFT STUFF
  // Mapping of (level number => NFT address)
  mapping(uint256 => address) public _NFTs;

  // Property object, extra field for arbirtrary values in future
  struct NFTProperty {
    string pType;
    uint256 pValue;
    bytes32 extra;
  }

  mapping(address => NFTProperty[]) public nftPropertyChoices;

  function setNFTPropertiesForContract(address _contractAddress, NFTProperty[] memory _properties) external {
    require(hasRole(MODIFIER_ROLE, _msgSender()));
    for (uint256 i; i < _properties.length; i++) {
      nftPropertyChoices[_contractAddress].push(_properties[i]);
    }
  }

  function getNFTAddress(uint256 _contractId) external view returns (address) {
    return _NFTs[_contractId];
  }

  function getNFTProperty(uint256 _contractId, uint256 _index)
    external
    view
    returns (
      string memory pType,
      uint256 pValue,
      bytes32 extra
    )
  {
    address NFTAddress = _NFTs[_contractId];
    NFTProperty memory properties = nftPropertyChoices[NFTAddress][_index];

    return (properties.pType, properties.pValue, properties.extra);
  }

  function getNFTPropertyCount(uint256 _contractId) external view returns (uint256) {
    address NFTAddress = _NFTs[_contractId];
    NFTProperty[] memory properties = nftPropertyChoices[NFTAddress];
    return properties.length;
  }

  // General-purpose mappings
  mapping(bytes32 => mapping(address => bool)) booleanMapStorage;
  uint256[] public booleanMapStorageCount;

  function getBooleanMapValue(string memory _key, address _address) external view returns (bool) {
    bytes32 key = stringToBytes32(_key);
    booleanMapStorage[key][_address];
  }

  mapping(bytes32 => address) addressStorage;
  uint256[] public addressStorageCount;

  function getAddressStorage(string memory _key) external view returns (address) {
    bytes32 key = stringToBytes32(_key);
    return addressStorage[key];
  }

  mapping(bytes32 => uint256) uintStorage;
  uint256[] public uintStorageCount;

  struct StateStruct {
    bytes32 name;
    mapping(bytes32 => bytes32) value;
  }

  struct ObjectStruct {
    StateStruct state;
    address owner;
    bool isObject;
  }

  function stringToBytes32(string memory source) public pure returns (bytes32 result) {
    bytes memory tempEmptyStringTest = bytes(source);
    if (tempEmptyStringTest.length == 0) {
      return 0x0;
    }

    assembly {
      result := mload(add(source, 32))
    }
  }
}
