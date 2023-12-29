// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./AccessControlEnumerableUpgradeable.sol";
import "./EnumerableMapUpgradeable.sol";
import "./EnumerableSetUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./IBeaconUpgradeable.sol";
import "./Strings.sol";
import "./SafeCast.sol";
import "./UUPSUpgradeable.sol";
import "./strings.sol";
import "./ReverseRegistrar.sol";
import "./INameResolver.sol";
import "./IUniswapV3Factory.sol";
import "./IUniswapV3Pool.sol";
import "./OracleLibrary.sol";

import "./IRarityPool.sol";

import "./IRareStakingRegistry.sol";

/// @author koloz, charlescrain
/// @title RareStakingRegistry
/// @notice The Staking Registry contract that holds info such as the staking contract for a given user and global staking stats.
/// @dev Made to be used with a UUPS Proxy.
contract RareStakingRegistry is IRareStakingRegistry, AccessControlEnumerableUpgradeable, UUPSUpgradeable {
  // ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
  // ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣀⣤⣤⣶⣶⣦⣤⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀
  // ⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣤⣾⠟⠋⠁⠀⠀⠀⠀⠀⠙⠻⣷⣄⠀⠀⠀⠀⠀⠀
  // ⠀⠀⠀⠀⠀⠀⠀⢀⣴⠟⢻⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠙⢷⡄⠀⠀⠀⠀
  // ⠀⠀⠀⠀⠀⠀⣠⡞⠁⠀⢸⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⣿⠀⣄⠀⠀
  // ⠀⠀⠀⠀⠀⣴⠋⠀⠀⠀⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⡟⢠⣿⡆⠀
  // ⠀⠀⠀⢀⣾⣧⣤⠤⠶⠾⣿⣦⣄⣀⠀⠀⠀⠀⠀⠀⣀⣠⡴⠞⠋⣠⣿⠟⠀⠀
  // ⠀⠀⠀⣼⠟⠁⠀⠀⠀⠀⠀⠈⠙⠻⢿⣿⣿⣿⠿⠛⠋⣁⣤⣶⡿⠟⠁⠀⠀⠀
  // ⠀⠀⣼⡇⠀⠀⠀⠀⠀⠀⠀⠀⣠⡾⠟⢉⣁⣤⣶⠾⠟⠋⠉⠀⠀⠀⠀⠀⠀⠀
  // ⠀⢠⣿⠀⢠⣾⣿⡆⠀⠀⣠⡾⠋⣠⣴⡿⠋⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
  // ⠀⢸⣿⠀⠘⠛⠛⠁⣠⣾⠏⢀⣾⡿⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
  // ⠀⠈⣿⡄⠀⠀⣠⣾⠟⢁⣴⡿⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
  // ⠀⠀⠈⠻⠿⠿⠛⢁⣴⡿⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
  // ⠀⠀⠀⠀⠀⠀⠚⠛⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
  // ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀

  using strings for *;
  using SafeCast for uint256;
  using SafeCast for uint128;

  /*//////////////////////////////////////////////////////////////////////////
                              Structs
  //////////////////////////////////////////////////////////////////////////*/
  
  /// @notice A struct holding the Rarity pool staking address and the reward accumulator address.
  /// @dev Mainly for internal use since `Info` is exposed externally.
  struct RarityPoolContractPair {
    address stakingAddress;
    address rewardAddress;
  }

  /*//////////////////////////////////////////////////////////////////////////
                              Constants
  //////////////////////////////////////////////////////////////////////////*/

  /// @inheritdoc IRareStakingRegistry
  bytes32 public constant STAKING_INFO_SETTER_ROLE = keccak256("STAKING_INFO_SETTER_ROLE");

  /// @inheritdoc IRareStakingRegistry
  bytes32 public constant STAKING_STAT_SETTER_ADMIN_ROLE = keccak256("STAKING_STAT_SETTER_ADMIN_ROLE");

  /// @inheritdoc IRareStakingRegistry
  bytes32 public constant STAKING_STAT_SETTER_ROLE = keccak256("STAKING_STAT_SETTER_ROLE");

  /// @inheritdoc IRareStakingRegistry
  bytes32 public constant STAKING_CONFIG_SETTER_ROLE = keccak256("STAKING_CONFIG_SETTER_ROLE");

  /// @inheritdoc IRareStakingRegistry
  bytes32 public constant ENS_SETTER_ROLE = keccak256("ENS_SETTER_ROLE");

  /// @inheritdoc IRareStakingRegistry
  bytes32 public constant SWAP_POOL_SETTER_ROLE = keccak256("SWAP_POOL_SETTER_ROLE");

  /*//////////////////////////////////////////////////////////////////////////
                          Private Contract Storage
  //////////////////////////////////////////////////////////////////////////*/

  // Mapping of address to the User's staking info.
  mapping(address => RarityPoolContractPair) private userToRarityPoolPair;

  // Reverse map of staking pool address to the staking target.
  mapping(address => address) private rarityPoolToUser;

  // Mapping of ERC20 token address to the ETH/ERC20 Uniswap pool.
  mapping(address => address) private swapPools;

  // Mapping of total RARE staked by a user.
  mapping(address => uint256) private amountStakedByUser;

  // Mapping of total RARE staked by on a target.
  mapping(address => uint256) private amountStakedOnTarget;

  // ENS reverse registrar
  ReverseRegistrar private reverseRegistrar;

  // ENS name resolver
  INameResolver private resolver;

  // Round period length for all staking contracts to use.
  uint256 private periodLength;

  // Percent to burn on unstake .
  uint256 private deflationaryPercentage;

  // Address of RARE ERC20 token contract.
  address private rare;

  // Address of WETH ERC20 token contract.
  address private weth;

  // Percentage of price pair to RARE for Reward Swapping.
  uint256 private discountedPercent;

  // Address of the default payee.
  address private defaultPayee;

  /*//////////////////////////////////////////////////////////////////////////
                              Constructor
  //////////////////////////////////////////////////////////////////////////*/
  constructor() {
    _disableInitializers();
  }

  /*//////////////////////////////////////////////////////////////////////////
                              Initializer
  //////////////////////////////////////////////////////////////////////////*/
  function initialize(
    address _owner,
    address _reverseRegistrar,
    address _resolver,
    uint256 _periodLength,
    uint256 _deflationaryPercentage,
    uint256 _discountedPercent,
    address _rare,
    address _weth,
    address _defaultPayee
  ) external initializer {
    if (_periodLength > 365 days) revert PeriodLengthBeyondLimit();
    if (_deflationaryPercentage > 100_00) revert PercentageBeyondLimit();
    if (_discountedPercent > 100_00) revert PercentageBeyondLimit();
    if (_owner == address(0)) revert ZeroAddressUnsupported();
    if (_reverseRegistrar == address(0)) revert ZeroAddressUnsupported();
    if (_resolver == address(0)) revert ZeroAddressUnsupported();
    if (_rare == address(0)) revert ZeroAddressUnsupported();
    if (_weth == address(0)) revert ZeroAddressUnsupported();
    if (_defaultPayee == address(0)) revert ZeroAddressUnsupported();
    _grantRole(DEFAULT_ADMIN_ROLE, _owner);
    _setRoleAdmin(STAKING_STAT_SETTER_ROLE, STAKING_STAT_SETTER_ADMIN_ROLE);
    reverseRegistrar = ReverseRegistrar(_reverseRegistrar);
    resolver = INameResolver(_resolver);
    deflationaryPercentage = _deflationaryPercentage;
    periodLength = _periodLength;
    rare = _rare;
    weth = _weth;
    discountedPercent = _discountedPercent;
    defaultPayee = _defaultPayee;
    __AccessControlEnumerable_init();
    __UUPSUpgradeable_init();
  }

  /*//////////////////////////////////////////////////////////////////////////
                          Internal UUPS Functions
  //////////////////////////////////////////////////////////////////////////*/

  /// @inheritdoc UUPSUpgradeable
  function _authorizeUpgrade(address _implementation) internal view override {
    if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) revert Unauthorized();
    if (_implementation == address(0)) revert ZeroAddressUnsupported();
  }

  /*//////////////////////////////////////////////////////////////////////////
                            Admin Write Functions
  //////////////////////////////////////////////////////////////////////////*/

  function renounceRole(bytes32 role, address account) public virtual override(IAccessControlUpgradeable, AccessControlUpgradeable) {
    if (role == DEFAULT_ADMIN_ROLE && getRoleMemberCount(role) == 1) {
      revert RenouncingAdmin();
    }

    super.renounceRole(role, account);
  }

  /// @dev Requires the caller to have the {STAKING_INFO_SETTER_ROLE} access control role.
  function setStakingAddresses(address _user, address _stakingAddress, address _rewardSwapAddress) external {
    if (!hasRole(STAKING_INFO_SETTER_ROLE, msg.sender)) revert Unauthorized();
    if (_user == address(0)) revert ZeroAddressUnsupported();
    if (_stakingAddress == address(0)) revert ZeroAddressUnsupported();
    if (_rewardSwapAddress == address(0)) revert ZeroAddressUnsupported();
    if (userToRarityPoolPair[_user].stakingAddress != address(0)) revert StakingContractAlreadyExists();
    userToRarityPoolPair[_user] = RarityPoolContractPair(_stakingAddress, _rewardSwapAddress);
    rarityPoolToUser[_stakingAddress] = _user;
  }

  /// @inheritdoc IRareStakingRegistry
  /// @dev Requires the caller to have the {STAKING_STAT_SETTER_ROLE} access control role.
  function increaseAmountStaked(address _staker, address _stakedOn, uint256 _amount) external {
    if (!hasRole(STAKING_STAT_SETTER_ROLE, msg.sender)) revert Unauthorized();
    amountStakedByUser[_staker] += _amount;
    amountStakedOnTarget[_stakedOn] += _amount;
  }

  /// @inheritdoc IRareStakingRegistry
  /// @dev Requires the caller to have the {STAKING_STAT_SETTER_ROLE} access control role.
  function decreaseAmountStaked(address _staker, address _stakedOn, uint256 _amount) external {
    if (!hasRole(STAKING_STAT_SETTER_ROLE, msg.sender)) revert Unauthorized();
    amountStakedByUser[_staker] -= _amount;
    amountStakedOnTarget[_stakedOn] -= _amount;
  }

  /// @inheritdoc IRareStakingRegistry
  /// @dev Requires the caller to have the {STAKING_CONFIG_SETTER_ROLE} access control role.
  function setDefaultPayee(address _payee) external {
    if (_payee == address(0)) revert ZeroAddressUnsupported();
    if (!hasRole(STAKING_CONFIG_SETTER_ROLE, msg.sender)) revert Unauthorized();
    defaultPayee = _payee;
    emit DefaultPayeeUpdated(_payee);
  }

  /// @inheritdoc IRareStakingRegistry
  /// @dev Requires the caller to have the {STAKING_CONFIG_SETTER_ROLE} access control role.
  function setDeflationaryPercentage(uint256 _percentage) external {
    if (_percentage > 100_00) revert PercentageBeyondLimit();
    if (!hasRole(STAKING_CONFIG_SETTER_ROLE, msg.sender)) revert Unauthorized();
    deflationaryPercentage = _percentage;
    emit DeflationaryPercentageUpdated(_percentage);
  }

  /// @inheritdoc IRareStakingRegistry
  /// @dev Requires the caller to have the {STAKING_CONFIG_SETTER_ROLE} access control role.
  function setDiscountPercentage(uint256 _percentage) external {
    if (_percentage > 100_00) revert PercentageBeyondLimit();
    if (!hasRole(STAKING_CONFIG_SETTER_ROLE, msg.sender)) revert Unauthorized();
    discountedPercent = _percentage;
    emit DiscountPercentageUpdated(_percentage);
  }

  /// @inheritdoc IRareStakingRegistry
  /// @dev Requires the caller to have the {STAKING_CONFIG_SETTER_ROLE} access control role.
  function setPeriodLength(uint256 _periodLength) external {
    if (_periodLength > 365 days) revert PeriodLengthBeyondLimit();
    if (!hasRole(STAKING_CONFIG_SETTER_ROLE, msg.sender)) revert Unauthorized();
    periodLength = _periodLength;
    emit PeriodLengthUpdated(_periodLength);
  }

  /// @inheritdoc IRareStakingRegistry
  /// @dev Requires the caller to have the {ENS_SETTER_ROLE} access control role.
  function setReverseRegistrar(address _reverseRegistrar) external {
    if (_reverseRegistrar == address(0)) revert ZeroAddressUnsupported();
    if (!hasRole(ENS_SETTER_ROLE, msg.sender)) revert Unauthorized();
    reverseRegistrar = ReverseRegistrar(_reverseRegistrar);
    emit ReverseRegistrarUpdated(_reverseRegistrar);
  }

  /// @inheritdoc IRareStakingRegistry
  /// @dev Requires the caller to have the {ENS_SETTER_ROLE} access control role.
  function setResolver(address _resolver) external {
    if (_resolver == address(0)) revert ZeroAddressUnsupported();
    if (!hasRole(ENS_SETTER_ROLE, msg.sender)) revert Unauthorized();
    resolver = INameResolver(_resolver);
    emit ResolverUpdated(_resolver);
  }

  /// @inheritdoc IRareStakingRegistry
  /// @dev Requires the caller to have the {SWAP_POOL_SETTER_ROLE} of the contract.
  function setSwapPool(address _uniswapPool, address _token) external {
    // _token must be part of the pool
    if (IUniswapV3Pool(_uniswapPool).token0() != _token && IUniswapV3Pool(_uniswapPool).token1() != _token) {
      revert InvalidPool();
    }

    // weth must be part of the pool
    if (IUniswapV3Pool(_uniswapPool).token0() != weth && IUniswapV3Pool(_uniswapPool).token1() != weth) {
      revert InvalidPool();
    }
    if (!hasRole(SWAP_POOL_SETTER_ROLE, msg.sender)) {
      revert Unauthorized();
    }
    swapPools[_token] = _uniswapPool;
    emit SetSwapPool(_uniswapPool, _token);
  }

  /// @inheritdoc IRareStakingRegistry
  /// @dev Only staking pool contracts can call this.
  function transferRareFrom(address _from, address _to, uint256 _amount) external {
    IERC20Upgradeable _rare = IERC20Upgradeable(rare);
    if (_rare.allowance(_from, address(this)) < _amount) {
      revert InsufficientRareAllowance();
    }
    if (rarityPoolToUser[msg.sender] == address(0)) revert Unauthorized();
    SafeERC20Upgradeable.safeTransferFrom(_rare, _from, _to, _amount);
  }

  /*//////////////////////////////////////////////////////////////////////////
                          External Read Functions
  //////////////////////////////////////////////////////////////////////////*/

  /// @inheritdoc IRareStakingRegistry
  function getDiscountPercentage() external view returns (uint256) {
    return discountedPercent;
  }

  /// @inheritdoc IRareStakingRegistry
  function getDefaultPayee() external view returns (address) {
    return defaultPayee;
  }

  /// @inheritdoc IRareStakingRegistry
  function getSwapPool(address _token) external view returns (address) {
    return swapPools[_token];
  }

  /// @inheritdoc IRareStakingRegistry
  function getWethAddress() external view returns (address) {
    return weth;
  }

  /// @inheritdoc IRareStakingRegistry
  function getRareAddress() external view returns (address) {
    return rare;
  }

  /// @inheritdoc IRareStakingRegistry
  function getDeflationaryPercentage() external view returns (uint256) {
    return deflationaryPercentage;
  }

  /// @inheritdoc IRareStakingRegistry
  function getPeriodLength() external view returns (uint256) {
    return periodLength;
  }

  /// @inheritdoc IRareStakingRegistry
  function getStakingInfoForUser(address _user) external view returns (Info memory) {
    strings.slice memory name = resolver.name((reverseRegistrar.node(_user))).toSlice();
    Info memory info;
    info.stakingAddress = userToRarityPoolPair[_user].stakingAddress;
    info.rewardAddress = userToRarityPoolPair[_user].rewardAddress;
    if (name.len() != 0) {
      name.rsplit(".".toSlice());
      info.name = ("Synthetic RARE | ".toSlice()).concat(name);
      info.symbol = ("xRARE_".toSlice()).concat(upper(name.toString()).toSlice());
      return info;
    }
    string memory userStr = Strings.toHexString(_user);
    strings.slice memory beginning = _substring(userStr, 6, 0).toSlice();
    strings.slice memory end = _substring(userStr, 4, 35).toSlice();
    strings.slice memory stakingNumber = beginning.concat(end).toSlice();
    info.name = ("Synthetic RARE | ".toSlice()).concat(stakingNumber);
    info.symbol = ("xRARE_".toSlice()).concat(stakingNumber);
    return info;
  }

  /// @inheritdoc IRareStakingRegistry
  function getStakingAddressForUser(address _user) external view returns (address) {
    return userToRarityPoolPair[_user].stakingAddress;
  }

  /// @inheritdoc IRareStakingRegistry
  function getRewardAccumulatorAddressForUser(address _user) external view returns (address) {
    return userToRarityPoolPair[_user].rewardAddress;
  }

  /// @inheritdoc IRareStakingRegistry
  function getTotalAmountStakedByUser(address _user) external view returns (uint256 amount) {
    return amountStakedByUser[_user];
  }

  /// @inheritdoc IRareStakingRegistry
  function getTotalAmountStakedOnUser(address _user) external view returns (uint256 amount) {
    return amountStakedOnTarget[_user];
  }

  /// @inheritdoc IRareStakingRegistry
  /// @dev Order maintained and zero address returned if it doesnt exist.
  /// @dev This function is intended to be called off chain.
  function getUsersForStakingAddresses(address[] calldata _stakingAddrs) external view returns (address[] memory) {
    address[] memory users = new address[](_stakingAddrs.length);

    for (uint256 i = 0; i < _stakingAddrs.length; i++) {
      try IRarityPool(_stakingAddrs[i]).getTargetBeingStakedOn() returns (address user) {
        users[i] = user;
      } catch {
        users[i] = address(0);
      }
    }

    return users;
  }

  /*//////////////////////////////////////////////////////////////////////////
                          Internal Read Functions
  //////////////////////////////////////////////////////////////////////////*/

  /// @notice Converts all the values of a string to their corresponding upper case value. Taken from: https://github.com/willitscale/solidity-util
  /// @param _base When being used for a data type this is the extended object otherwise this is the string base to convert to upper case
  /// @return string
  function upper(string memory _base) internal pure returns (string memory) {
    bytes memory _baseBytes = bytes(_base);
    for (uint256 i = 0; i < _baseBytes.length; i++) {
      _baseBytes[i] = _upper(_baseBytes[i]);
    }
    return string(_baseBytes);
  }

  /// @notice Convert an alphabetic character to upper case and return the original value when not alphabetic. Taken from: https://github.com/willitscale/solidity-util
  /// @param _b1 The byte to be converted to upper case
  /// @return bytes1 The converted value if the passed value was alphabetic and in a lower case otherwise returns the original value
  function _upper(bytes1 _b1) private pure returns (bytes1) {
    if (_b1 >= 0x61 && _b1 <= 0x7A) {
      return bytes1(uint8(_b1) - 32);
    }

    return _b1;
  }

  /// @notice Extracts the part of a string based on the desired length and offset. The offset and length must not exceed the lenth of the base string. Taken from: https://github.com/willitscale/solidity-util
  /// @param _base When being used for a data type this is the extended object otherwise this is the string that will be used for extracting the sub string from
  /// @param _length The length of the sub string to be extracted from the base
  /// @param _offset The starting point to extract the sub string from
  /// @return string The extracted sub string
  function _substring(string memory _base, int256 _length, int256 _offset) internal pure returns (string memory) {
    bytes memory _baseBytes = bytes(_base);

    assert(uint256(_offset + _length) <= _baseBytes.length);

    string memory _tmp = new string(uint256(_length));
    bytes memory _tmpBytes = bytes(_tmp);

    uint256 j = 0;
    for (uint256 i = uint256(_offset); i < uint256(_offset + _length); i++) {
      _tmpBytes[j++] = _baseBytes[i];
    }

    return string(_tmpBytes);
  }
}
