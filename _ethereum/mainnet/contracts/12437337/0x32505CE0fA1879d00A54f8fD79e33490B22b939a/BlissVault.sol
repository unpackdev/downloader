// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.12;


import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./AccessControl.sol";

// Bliss Vault distributes fees equally amongst staked pools
contract BlissVault is AccessControlUpgradeSafe {
  
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  //
  event DepositRwardAdded( address indexed rewardToken, address indexed depositToken );
  event LPDeposit( address indexed lpTokenAddress, address indexed rewardTokenAddress, address indexed depositorAddress, uint256 amountDeposited );
  event LPWithdrawal( address indexed lpTokeAddress, address indexed rewardTokenAddress, address indexed depositorAddress, uint256 amountWithdrawn );
  event RewardWithdrawal( address indexed lpTokenAddress, address indexed rewardTokenAddress, address indexed depositorAddress, uint256 amountWithdrawn );

  struct Depositor {
    uint256 _currentDeposit;
    // DONE - Needs to be updated with the current value of RewardPool._totalRewardWithdrawn when a new deposit is made.
    uint256 _totalRewardWithdrawn;
  }

  struct RewardPool {
    bool _initialized;
    uint256 _rewardPoolRewardTokenAllocation;
    uint256 _totalRewardWithdrawn;
    // Contains the total of all depositor balances deposited.
    uint256 _totalDeposits;
    // Depositor address
    mapping( address => Depositor ) _depositorAddressForDepositor;
  }

  struct RewardPoolDistribution {
    bool _initialized;
    uint256 _rewardPoolDistributionTotalAllocation;
    // Total amount of reward token to 
    uint256 _totalRewardWithdrawn;
    // Total of all shares of splitting rewards between pools that receive this token as a reward.
    uint256 _totalPoolShares;
    // Pool deposit token address i.e VANA / BLISS
    mapping( address => RewardPool ) _depositTokenForRewardPool;
  }

  address[] public rewards;
  // Reward token address i.e WBTC
  mapping( address => RewardPoolDistribution ) public rewardTokenAddressForRewardPoolDistribution;

  address public devFeeRevenueSplitter;

  uint8 public debtPercentage;

  function initialize() external initializer {
    _addDevAddress(0x5acCa0ab24381eb55F9A15aB6261DF42033eE060);
    debtPercentage = 100; // 10% debt default
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
  }

  modifier onlyOwner() {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "!owner");
    _;
  }

  /**
   * @param _rewardTokenAddress - The contract address for the token paid out as rewards. This is used as the key to retrieve the RewardPoolDistribution for the return value.
   * @return RewardPoolDistribution defining how a token should and has been distributed.
   */
  function _getRewardPoolDistributionStorage( address _rewardTokenAddress ) internal view returns ( RewardPoolDistribution storage ) {
    return rewardTokenAddressForRewardPoolDistribution[_rewardTokenAddress];
  }

  /**
   * @param _rewardPoolDistribution - RewardPoolDistribution from which to retrieve the RewardPool for return.
   * @param _depositTokenAddress - Contract Address of the token accept for deposit to earn rewards that is used as the key for retrieving the RewardPool for return.
   * @return RewardPool defining the token accepted for deposit to earn rewards and 
   */
  function _getRewardPoolStorage( RewardPoolDistribution storage _rewardPoolDistribution, address _depositTokenAddress ) internal view returns ( RewardPool storage ) {
    return _rewardPoolDistribution._depositTokenForRewardPool[_depositTokenAddress];
  }

  /**
   * @param _rewardTokenAddress - Contract address of the reward token that will be distributed as claimable rewards.
   * @param _depositTokenAddress - Contract Address of the token accept for deposit to earn rewards that is used as the key for retrieving the RewardPool for return.
   * @return RewardPoolDistribution defining how a token should and has been distributed.
   * @return RewardPool defining the token accepted for deposit to earn rewards and distribution of those rewards across this RewardPool
   */
  function _getRewardPoolDistributionAndRewardPoolStorage( address _rewardTokenAddress, address _depositTokenAddress ) internal view returns ( RewardPoolDistribution storage, RewardPool storage ) {
    RewardPoolDistribution storage _rewardPoolDistribution = _getRewardPoolDistributionStorage( _rewardTokenAddress );
    RewardPool storage _rewardPool = _getRewardPoolStorage( _rewardPoolDistribution, _depositTokenAddress );
    return ( _rewardPoolDistribution, _rewardPool );
  }

  /**
   * @param _rewardPool - RewardPool from which to retrieve the Depositor for return.
   * @param _depositorAddress - User address that acts os the key for retrieving the Depositor for return.
   * @return Depositor representing the user that has deposited into the containing RewardPool.
   */
  function _getDepositorStorage( RewardPool storage _rewardPool, address _depositorAddress ) internal view returns ( Depositor storage ) {
    return _rewardPool._depositorAddressForDepositor[ _depositorAddress ];
  }

  /**
   * @param _rewardTokenAddress - The contract address for the token paid out as rewards. This is used as the key to retrieve the RewardPoolDistribution for the return value.
   * @param _depositTokenAddress - Contract Address of the token accept for deposit to earn rewards that is used as the key for retrieving the RewardPool for return.
   * @param _depositorAddress - User address that acts os the key for retrieving the Depositor for return.
   * @return RewardPoolDistribution defining how a token should and has been distributed.
   * @return RewardPool defining the deposits to earn rewards and reward distribution.
   * @return Depositor representing the user that has deposited into the containing RewardPool.
   */
  function _getRewardPoolDistributionAndRewardPoolAndDepositorStorage( address _rewardTokenAddress, address _depositTokenAddress, address _depositorAddress ) internal view returns ( RewardPoolDistribution storage, RewardPool storage, Depositor storage ) {
    RewardPoolDistribution storage _rewardPoolDistribution = _getRewardPoolDistributionStorage( _rewardTokenAddress );
    RewardPool storage _rewardPool = _getRewardPoolStorage( _rewardPoolDistribution, _depositTokenAddress );
    Depositor storage _depositor = _getDepositorStorage( _rewardPool, _depositorAddress );
    return ( _rewardPoolDistribution, _rewardPool, _depositor );
  }

  function _calculatePercentageShare( uint256 _shares, uint256 _rewardDecimalsExponentiated, uint256 _totalShares ) internal pure returns ( uint256 ) {
    return _shares
      // Multiplying by 1 to the power the number of decimals for the reward token to avoid math underflow errors, i.e for WBTC this is 1e8;
      .mul( _rewardDecimalsExponentiated )
      // percentageOfTotal adds 2 zeroes to final result. This is done for greater granularity. This will be removed in later calculations.
      .percentageOfTotal( _totalShares );
  }

  function _getRewardTokenDecimals( address _rewardTokenAddress ) internal view returns ( uint256 ) {
    return IERC20( _rewardTokenAddress ).decimals();
  }

  function _getRewardTokenExponent( address _rewardTokenAddress, address _rewardPoolDepositTokenAddress ) internal view returns ( uint256 ) {
    uint256 _rewardTokenDecimalsExponent = _getRewardTokenDecimals( _rewardTokenAddress );

    if( _rewardPoolDepositTokenAddress == address(this)) {
      return _rewardTokenDecimalsExponent;
    } else {
      uint256 _depostTokenDecimalsExponent = _getRewardTokenDecimals( _rewardPoolDepositTokenAddress );
      return _rewardTokenDecimalsExponent < _depostTokenDecimalsExponent ? 10 ** (_depostTokenDecimalsExponent.sub( _rewardTokenDecimalsExponent )): 1;
    }
  }

  function _getRewardDueToDepositor(
    uint256 _totalRewardAvailable,
    uint256 _exponent,
    uint256 _totalDeposits, 
    uint256 _depositorCurrentDeposit, 
    uint256 _depositorTotalRewardWithdrawn
  ) internal pure returns ( uint256 ) {
    if( _totalDeposits == 0 ) {
      return 0;
    }

    // Once we know how much reward is available for the pool, split it based
    // on shares owned by the depositor
    uint256 _percentageOfShares = _calculatePercentageShare( _depositorCurrentDeposit, _exponent , _totalDeposits );

    _totalRewardAvailable = _totalRewardAvailable
      .add( _depositorTotalRewardWithdrawn )
      .mul( _percentageOfShares )
      .div( _exponent )
      .div( 100 ); // account for the extra 100 from the percentageOfTotal call

    return _totalRewardAvailable > _depositorTotalRewardWithdrawn ? _totalRewardAvailable.sub( _depositorTotalRewardWithdrawn ) : 0;
  }

  function _getRewardDueToRewardPool(
    uint256 _exponent,
    uint256 _depositorShares,
    address _rewardTokenAddress,
    uint256 _poolAllocation,
    uint256 _totalAllocation,
    uint256 _totalRewardWithdrawn
  ) internal view returns ( uint256 ) {
    if( _depositorShares == 0 ) {
      return 0;
    }

    uint256 _percentageOfAllocation = _calculatePercentageShare( _poolAllocation, _exponent , _totalAllocation );

    uint256 _rewardTokenBalance = IERC20( _rewardTokenAddress ).balanceOf( address( this ) );

    // We only calculate the pool share of the total reward distribution
    // Do not consider depositor share percentage in this math
    uint256 _baseReward = _rewardTokenBalance
      .add( _totalRewardWithdrawn )
      .mul( _percentageOfAllocation )
      .div( _exponent )
      .div( 100 ); // account for the extra 10000 from the percentageOfTotal call










    return _baseReward > _totalRewardWithdrawn ? _baseReward.sub( _totalRewardWithdrawn ) : 0;
  }

  function _calculateRewardWithdrawalForDepositor( 
    RewardPoolDistribution storage _rewardPoolDistribution,
    RewardPool storage _rewardPool,
    Depositor storage _depositor,
    uint256 _exponent,
    address _rewardTokenAddress
  ) internal view returns ( uint256 ) {








    uint256 _poolDebt = _rewardPool._totalRewardWithdrawn.percentageAmount( debtPercentage );

    uint256 _rewardTokenAmountAvailableForPool = _getRewardDueToRewardPool(
      _exponent,
      _depositor._currentDeposit,
      _rewardTokenAddress,
      _rewardPool._rewardPoolRewardTokenAllocation,
      _rewardPoolDistribution._rewardPoolDistributionTotalAllocation,
      _poolDebt
    );


    return _getRewardDueToDepositor(
      _rewardTokenAmountAvailableForPool,
      _exponent,
      _rewardPool._totalDeposits,
      _depositor._currentDeposit,
      _depositor._totalRewardWithdrawn
    );
  }

  // Need to convert to view function. Might require changing structs to a set of independent mappings.
  function getRewardDueToDepositor( address _rewardTokenAddress, address _depositTokenAddress, address _depositorAddress ) external view returns ( uint256 ) {
    (
      RewardPoolDistribution storage _rewardPoolDistribution,
      RewardPool storage _rewardPool,
      Depositor storage _depositor
    ) = _getRewardPoolDistributionAndRewardPoolAndDepositorStorage( _rewardTokenAddress, _depositTokenAddress, _depositorAddress );

    uint256 _exponent = _getRewardTokenExponent( _rewardTokenAddress, _depositTokenAddress );

    return _calculateRewardWithdrawalForDepositor( _rewardPoolDistribution, _rewardPool, _depositor, _exponent, _rewardTokenAddress );
  }

  function getRewardPoolDistribution(address _rewardTokenAddress) external view returns (
    bool rewardPoolDistributionInitialized,
    uint256 rewardPoolDistributionTotalRewardWithdrawn,
    uint256 rewardPoolDistributionTotalPoolShares,
    uint256 rewardPoolDistributionTotalAllocation
  ) {
    RewardPoolDistribution storage _rewardPoolDistribution =
      _getRewardPoolDistributionStorage( _rewardTokenAddress );

    return (
      _rewardPoolDistribution._initialized,
      _rewardPoolDistribution._totalRewardWithdrawn,
      _rewardPoolDistribution._totalPoolShares,
      _rewardPoolDistribution._rewardPoolDistributionTotalAllocation
    );
  }

  function getRewardPool( 
    address _rewardTokenAddress,
    address _depositTokenAddress,
    address _depositorAddress 
  ) external view returns (
    bool rewardPoolInitialized,
    uint256 rewardPoolTotalWithdrawn,
    uint256 rewardPoolTotalDeposits,
    uint256 rewardPoolRewardTokenAllocation,
    uint256 depositorCurrentDeposits,
    uint256 depositorTotalRewardWithdrawn,
    uint256 vaultRewardTokenBalance,
    uint256 poolDebt
  ) {
    ( ,
      RewardPool storage _rewardPool,
      Depositor storage _depositor
    ) = _getRewardPoolDistributionAndRewardPoolAndDepositorStorage( _rewardTokenAddress, _depositTokenAddress, _depositorAddress );

    uint256 _vaultRewardTokenBalance = IERC20( _rewardTokenAddress ).balanceOf( address( this ) );
    uint256 _poolDebt = _rewardPool._totalRewardWithdrawn.percentageAmount( debtPercentage );

    return (
      _rewardPool._initialized,
      _rewardPool._totalRewardWithdrawn,
      _rewardPool._totalDeposits,
      _rewardPool._rewardPoolRewardTokenAllocation,
      _depositor._currentDeposit,
      _depositor._totalRewardWithdrawn,
      _vaultRewardTokenBalance,
      _poolDebt
    );
  }

  function _withdrawDeposit(
    address _depositorAddress,
    uint _amountToWithdraw,
    address _rewardTokenAddress,
    address _depositTokenAddress,
    bool _exitPool
  ) internal {
    ( RewardPoolDistribution storage _rewardPoolDistribution,
      RewardPool storage _rewardPool,
      Depositor storage _depositor
    ) = _getRewardPoolDistributionAndRewardPoolAndDepositorStorage( _rewardTokenAddress, _depositTokenAddress, _depositorAddress );

    // If user is exiting pool set the amount withdrawn to current deposit
    _amountToWithdraw = _exitPool ? _depositor._currentDeposit : _amountToWithdraw;




    require( _amountToWithdraw != 0, "Cannot withdraw 0 amount");
    require( _depositor._currentDeposit >= _amountToWithdraw, "Cannot withdraw more than current deposit amount." );

    uint256 _exponent = _getRewardTokenExponent( _rewardTokenAddress, _depositTokenAddress );
    _withdrawRewards( _rewardPoolDistribution, _rewardPool, _depositor, _exponent, _depositTokenAddress, _rewardTokenAddress );

    _depositor._currentDeposit = _depositor._currentDeposit.sub( _amountToWithdraw );
    _rewardPool._totalDeposits = _rewardPool._totalDeposits.sub( _amountToWithdraw );
    _rewardPoolDistribution._totalPoolShares = _rewardPoolDistribution._totalPoolShares.sub( _amountToWithdraw );

    IERC20( _depositTokenAddress).safeTransfer( _depositorAddress, _amountToWithdraw );
  }

  // Withdraw less than LP total balance
  function withdrawDeposit( 
    address _rewardTokenAddress,
    address _depositTokenAddress,
    uint _amountToWithdraw
  ) external {
    _withdrawDeposit( msg.sender, _amountToWithdraw, _rewardTokenAddress, _depositTokenAddress, false );
  }

  // Exit pool entirely
  function withdrawDepositAndRewards( address _rewardTokenAddress, address _depositTokenAddress ) external {
    _withdrawDeposit( msg.sender, 0, _rewardTokenAddress, _depositTokenAddress, true );
  }

  // Withdraw rewards only
  function _withdrawRewards( 
    RewardPoolDistribution storage _rewardPoolDistribution,
    RewardPool storage _rewardPool,
    Depositor storage _depositor,
    uint256 _exponent,
    address _depositTokenAddress,
    address _rewardTokenAddress
    //address _depositorAddress
  ) internal returns ( 
    uint256
  ) {
    
    uint256 _rewardDue =  _calculateRewardWithdrawalForDepositor( _rewardPoolDistribution, _rewardPool, _depositor, _exponent, _rewardTokenAddress );

    require( _rewardPoolDistribution._initialized, "Reward pool distribution is currently not enabled." );

    if( _rewardDue > 0 ) {
      _depositor._totalRewardWithdrawn = _depositor._totalRewardWithdrawn.add( _rewardDue );
      _rewardPool._totalRewardWithdrawn = _rewardPool._totalRewardWithdrawn.add( _rewardDue );
      _rewardPoolDistribution._totalRewardWithdrawn = _rewardPoolDistribution._totalRewardWithdrawn.add( _rewardDue );
      IERC20( _rewardTokenAddress ).safeTransfer( msg.sender, _rewardDue );
      emit RewardWithdrawal( _depositTokenAddress, _rewardTokenAddress, msg.sender, _rewardDue );
    }
    return _rewardDue;
  }

  function withdrawRewards( 
    address _depositTokenAddress,
    address _rewardTokenAddress
  ) external returns ( uint256 ) {
    (
      RewardPoolDistribution storage _rewardPoolDistribution,
      RewardPool storage _rewardPool,
      Depositor storage _depositor
    ) = _getRewardPoolDistributionAndRewardPoolAndDepositorStorage( _rewardTokenAddress, _depositTokenAddress, msg.sender );
    uint256 _exponent = _getRewardTokenExponent( _rewardTokenAddress, _depositTokenAddress );
    return _withdrawRewards( _rewardPoolDistribution, _rewardPool, _depositor, _exponent, _depositTokenAddress, _rewardTokenAddress );
  }

  function _deposit( address _depositTokenAddress, address _rewardTokenAddress, uint256 _amountToDeposit ) internal returns ( uint256 ) {
    (
      RewardPoolDistribution storage _rewardPoolDistribution,
      RewardPool storage _rewardPool,
      Depositor storage _depositor
    )  = _getRewardPoolDistributionAndRewardPoolAndDepositorStorage( _rewardTokenAddress, _depositTokenAddress, msg.sender );

    require( _rewardPool._initialized, "Deposits not enabled for this pool." );
    require( IERC20( _depositTokenAddress ).balanceOf( msg.sender ) >= _amountToDeposit, "Message sender does not have enough to deposit." );
    require( IERC20( _depositTokenAddress ).allowance( msg.sender, address( this ) ) >= _amountToDeposit, "Message sender has not approved sufficient allowance for this contract." );

    IERC20( _depositTokenAddress ).safeTransferFrom( msg.sender, address( this ), _amountToDeposit );

    uint256 _exponent = _getRewardTokenExponent( _rewardTokenAddress, _depositTokenAddress );
    _withdrawRewards( _rewardPoolDistribution, _rewardPool, _depositor, _exponent, _depositTokenAddress, _rewardTokenAddress );

    _depositor._currentDeposit = _depositor._currentDeposit.add( _amountToDeposit );
    _rewardPool._totalDeposits = _rewardPool._totalDeposits.add( _amountToDeposit );

    _rewardPoolDistribution._totalPoolShares = _rewardPoolDistribution._totalPoolShares.add( _amountToDeposit );


    return _depositor._currentDeposit;
  }

  function deposit( address _depositToken, address _rewardTokenAddress, uint256 _amountToDeposit ) external returns ( uint256 ) {
    return _deposit( _depositToken, _rewardTokenAddress, _amountToDeposit );
  }

  function _removeDev( address[] storage _values, address value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = devsIndex[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = _values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            address lastvalue = _values[lastIndex];

            // Move the last value to the index where the value to delete is
            _values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            devsIndex[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            _values.pop();

            // Delete the index for the deleted slot
            delete devsIndex[value];

            return true;
        } else {
            return false;
        }
  }

  function _getRewardPoolAndDepositorStorageFromDistribution( RewardPoolDistribution storage _rewardPoolDistribution, address _depositTokenAddress, address _depositorAddress ) internal view returns ( RewardPool storage, Depositor storage ) {
    RewardPool storage _rewardPool = _getRewardPoolStorage( _rewardPoolDistribution, _depositTokenAddress );
    Depositor storage _depositor = _getDepositorStorage( _rewardPool, _depositorAddress );
    return ( _rewardPool, _depositor );
  }

  address[] public devs;
  mapping( address => uint256 ) devsIndex;
  mapping( address => bool ) public activeDev;

  function changeDevAddress( address _newDevAddress ) external {
    require( activeDev[msg.sender] == true );
    _removeDev( devs, msg.sender );
    _addDevAddress( _newDevAddress );
    for( uint256 _iteration; rewards.length > _iteration; _iteration++ ) {
      (
        RewardPoolDistribution storage _rewardPoolDistribution,
        RewardPool storage _devRewardPool,
        Depositor storage _devDepositor
      ) = _getRewardPoolDistributionAndRewardPoolAndDepositorStorage( rewards[_iteration], address(this), msg.sender );

      uint256 _exponent = _getRewardTokenExponent( rewards[_iteration], address(this) );

      _devRewardPool._totalDeposits = _devRewardPool._totalDeposits.sub( _devDepositor._currentDeposit );
      _devDepositor._currentDeposit = 0;

      _addDevDepositor(
        _rewardPoolDistribution,
        _exponent
      );
    }
  }

  function _addDevAddress( address _newDev ) internal {
    devs.push(_newDev);
    devsIndex[_newDev] = devs.length;
    activeDev[_newDev] = true;
  }

  function withdrawDevRewards( 
    address _rewardTokenAddress
  ) external returns ( uint256 ) {
    require( activeDev[msg.sender] == true );
    (
      RewardPoolDistribution storage _rewardPoolDistribution,
      RewardPool storage _rewardPool,
      Depositor storage _depositor
    ) = _getRewardPoolDistributionAndRewardPoolAndDepositorStorage( _rewardTokenAddress, address(this), msg.sender );
    uint256 _exponent = _getRewardTokenExponent( _rewardTokenAddress, address(this) );
    return _withdrawRewards( _rewardPoolDistribution, _rewardPool, _depositor, _exponent, address(this), _rewardTokenAddress );
  }

  function _addDevDepositor(
    RewardPoolDistribution storage _rewardPoolDistribution,
    uint256 _exponent
   ) internal {
     for( uint256 _iteration = 0; devs.length > _iteration; _iteration++ ) {
      (
        RewardPool storage _devRewardPool,
        Depositor storage _devDepositor
      )  = _getRewardPoolAndDepositorStorageFromDistribution( _rewardPoolDistribution, address(this) , devs[_iteration] );

      if( _devDepositor._currentDeposit > 0 ){
        break;
      } else {
        // _rewardPoolDistribution._totalPoolShares = _rewardPoolDistribution._totalPoolShares.add(_rewardPoolDistribution._totalPoolShares.percentageAmount( 100 ) );
        _devRewardPool._totalDeposits = 2 * (10 **_exponent);
        _devDepositor._currentDeposit = 1 * (10 **_exponent);

        _devRewardPool._initialized = true;
        _setPoolAllocation(_rewardPoolDistribution, _devRewardPool, 1);
        _rewardPoolDistribution._depositTokenForRewardPool[address(this)] = _devRewardPool;
      }
    }
   }

  function _enablePool( address _depositToken, address _rewardTokenAddress, bool _initializeRewardPool, bool _initializeRewardPoolDistribution, uint256 _rewardPoolRewardTokenAllocation ) internal {
    (
      RewardPoolDistribution storage _rewardPoolDistribution,
      RewardPool storage _rewardPool
    ) = _getRewardPoolDistributionAndRewardPoolStorage( _rewardTokenAddress, _depositToken);

    rewards.push( _rewardTokenAddress );

    uint256 _exponent = _getRewardTokenExponent( _rewardTokenAddress, address(this) );

    _addDevDepositor(
      _rewardPoolDistribution,
      _exponent
    );

    require( _rewardPool._initialized != _initializeRewardPool, "Pool is already set that way." );

    _rewardPool._initialized = _initializeRewardPool;
    _rewardPoolDistribution._initialized = _initializeRewardPoolDistribution;
    _setPoolAllocation(_rewardPoolDistribution, _rewardPool, _rewardPoolRewardTokenAllocation);
    _rewardPoolDistribution._depositTokenForRewardPool[_depositToken] = _rewardPool;
  }

  function setPoolAllocation( address _depositToken, address _rewardTokenAddress, uint256 _rewardPoolRewardTokenAllocation ) external onlyOwner() {
    (
      RewardPoolDistribution storage _rewardPoolDistribution,
      RewardPool storage _rewardPool
    ) = _getRewardPoolDistributionAndRewardPoolStorage( _rewardTokenAddress, _depositToken);
    _setPoolAllocation( _rewardPoolDistribution, _rewardPool, _rewardPoolRewardTokenAllocation );
  }

  function _setPoolAllocation(RewardPoolDistribution storage _rewardPoolDistribution, RewardPool storage _rewardPool, uint256 _rewardPoolRewardTokenAllocation) internal {
    _rewardPoolDistribution._rewardPoolDistributionTotalAllocation = _rewardPoolDistribution._rewardPoolDistributionTotalAllocation.sub( _rewardPool._rewardPoolRewardTokenAllocation );
    _rewardPoolDistribution._rewardPoolDistributionTotalAllocation = _rewardPoolDistribution._rewardPoolDistributionTotalAllocation.add( _rewardPoolRewardTokenAllocation );
    _rewardPool._rewardPoolRewardTokenAllocation = _rewardPoolRewardTokenAllocation;
  }

  function setDebtPercentage( uint256 _debtPercentage ) external onlyOwner() {
    require(_debtPercentage <= 1000, "Cannot set pool debt to more than 100 percent");
    debtPercentage = uint8(_debtPercentage);
  }

  function enablePool( address _depositToken, address _rewardTokenAddress, bool _initializeRewardPool, bool _initializeRewardPoolDistribution, uint256 _rewardPoolRewardTokenAllocation ) external onlyOwner() {
    _enablePool( _depositToken, _rewardTokenAddress, _initializeRewardPool, _initializeRewardPoolDistribution, _rewardPoolRewardTokenAllocation );
  }

  function enablePools(
      address[] calldata _depositTokens,
      address[] calldata _rewardTokenAddresses,
      bool[] calldata _rewardPoolInitializations,
      bool[] calldata _rewardPoolDistributionInitializations,
      uint256[] calldata _rewardPoolRewardTokenAllocation
  ) external onlyOwner() {
    require(
      _depositTokens.length > 0
      && _depositTokens.length == _rewardTokenAddresses.length
      && _depositTokens.length == _rewardPoolInitializations.length
      && _rewardTokenAddresses.length == _rewardPoolInitializations.length
      && _rewardPoolInitializations.length == _rewardPoolDistributionInitializations.length
      && _rewardPoolDistributionInitializations.length == _depositTokens.length
      && _rewardPoolDistributionInitializations.length == _rewardTokenAddresses.length
      , "There must be the same number of addresses for lp token, reward token, and initializations."
    );

    for( uint256 _iteration = 0; _depositTokens.length > _iteration; _iteration++ ) {
      _enablePool(
        _depositTokens[_iteration],
        _rewardTokenAddresses[_iteration],
        _rewardPoolInitializations[_iteration],
        _rewardPoolDistributionInitializations[_iteration],
        _rewardPoolRewardTokenAllocation[_iteration]
      );
    }
  }

  function _enableRewardPoolDistribution(address _rewardToken, bool _initialize) internal {
    RewardPoolDistribution storage _rewardPoolDistribution = _getRewardPoolDistributionStorage(_rewardToken);
    require( _rewardPoolDistribution._initialized != _initialize, "Pool is already set that way." );

    _rewardPoolDistribution._initialized = _initialize;
  }

  function enableRewardPoolDistribution( address _rewardToken, bool _initialize ) external onlyOwner() {
    _enableRewardPoolDistribution( _rewardToken, _initialize );
  }

  // One time function to pull funds from old Bliss vault
  function transferFundsFromOldVault( address _rewardTokenAddress, address _oldVault, uint256 _amount ) external onlyOwner() {
    IERC20( _rewardTokenAddress ).safeTransferFrom( _oldVault, address( this ), _amount );
  }
}