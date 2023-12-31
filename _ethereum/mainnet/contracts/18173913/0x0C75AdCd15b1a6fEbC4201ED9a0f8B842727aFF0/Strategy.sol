// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma abicoder v2;

import "./OwnableUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./ITreasury.sol";
import "./IMarket.sol";
import "./IStrategy.sol";

contract Strategy is OwnableUpgradeable, IStrategy {
  using SafeMathUpgradeable for uint256;

  /**********
   * Events *
   **********/

  /// @notice Emitted when the allocation point is changed
  /// @param earn the new point of earn
  /// @param platform the new point of platform
  /// @param insuranceFund the new point of insurance fund
  event UpdateAllocPoint(
    uint256 earn,
    uint256 platform,
    uint256 insuranceFund
  );

  /// @notice Emitted when the staking contract is changed.
  /// @param staking The address of new staking.
  event UpdateStaking(address staking);

  /// @notice Emitted when the revenue contract is changed.
  /// @param revenue The address of new revenue.
  event UpdateRevenue(address revenue);

  /// @notice Emitted when the treasury contract is changed.
  /// @param treasury The address of new treasury.
  event UpdateTreasury(address treasury);

  /// @notice Emitted when the platform contract is changed.
  /// @param platform The address of new platform.
  event UpdatePlatform(address platform);

  /// @notice Emitted when the insurance fund contract is changed.
  /// @param insuranceFund The address of new insurance fund.
  event UpdateInsuranceFund(address insuranceFund);

  /// @notice Emitted when emergency withdraw all assets.
  /// @param treasuryAmount The amount of treasury asset.
  /// @param feeAmount The amount of mint/redeem fee.
  event EmergencyWithdraw(uint256 treasuryAmount, uint256 feeAmount);

  /// @notice Emitted when strategy mint fToken/xToken.
  /// @param recipient The address of receiver for fToken and xToken.
  /// @param baseIn The amount of base token supplied.
  /// @param fTokenMinted The amount of fToken should be minted.
  /// @param xTokenMinted The amount of xToken should be minted.
  event StrategyMint(
    address recipient,
    uint256 baseIn,
    uint256 fTokenMinted,
    uint256 xTokenMinted
  );
  
  /***********
   * Structs *
   ***********/

  struct AllocPoint {
    uint256 earn;
    uint256 platform;
    uint256 insuranceFund;
  }

  /*************
   * Variables *
   *************/

  /// @notice The address of treasury contract.
  address public treasury;

  /// @notice The address of staking contract.
  address public staking;

  /// @notice The address of revenue contract.
  address public revenue;
  
  /// @notice The address of platform contract.
  address public platform;

  /// @notice The address of insurance fund contract.
  address public insuranceFund;
  
  /// @notice The point of asset allocation.
  AllocPoint public allocPoint;

  /************
   * Modifier *
   ************/

  modifier onlyStaking() {
    require(staking == msg.sender, "Only staking");
    _;
  }

  modifier onlyRevenue() {
    require(revenue == msg.sender, "Only revenue");
    _;
  }

  /***************
   * Constructor *
   ***************/

  function initialize(
    address _treasury,
    address _staking,
    address _revenue,
    address _platform,
    address _insuranceFund
  ) external initializer {
    OwnableUpgradeable.__Ownable_init();

    treasury = _treasury;
    staking = _staking;
    revenue = _revenue;
    platform = _platform;
    insuranceFund = _insuranceFund;
  }

  /*************************
   * Public View Functions *
   *************************/

  function totalAllocPoint() public view returns (uint256) {
    return allocPoint.earn + allocPoint.platform + allocPoint.insuranceFund;
  }

  /****************************
   * Public Mutated Functions *
   ****************************/
  
  /// @inheritdoc IStrategy
  function mintByStaking() external override onlyStaking returns (uint256 _fTokenMinted, uint256 _xTokenMinted) {
    ITreasury _treasury = ITreasury(treasury);
    IERC20Upgradeable baseToken = IERC20Upgradeable(_treasury.baseToken());
    uint256 balance = baseToken.balanceOf(treasury);
    uint256 total = _treasury.totalBaseToken();
    uint256 baseIn = 0;

    if (balance > total) {
      baseIn = balance.sub(total);
    }

    _treasury.transferToStrategy(baseIn);

    return _allocate(baseIn, staking);
  }

  /// @inheritdoc IStrategy
  function mintByStaking(uint256 _baseIn) external override onlyStaking returns (uint256 _fTokenMinted, uint256 _xTokenMinted) {
    ITreasury _treasury = ITreasury(treasury);
    IERC20Upgradeable baseToken = IERC20Upgradeable(_treasury.baseToken());
    uint256 balance = baseToken.balanceOf(treasury);
    uint256 total = _treasury.totalBaseToken();
    require(balance.sub(total) > _baseIn, "baseIn exceeds balance");

    _treasury.transferToStrategy(_baseIn);

    return _allocate(_baseIn, staking);
  }

  /// @inheritdoc IStrategy
  function mintByRevenue() external override onlyRevenue returns (uint256 _fTokenMinted, uint256 _xTokenMinted) {
    ITreasury _treasury = ITreasury(treasury);
    IERC20Upgradeable baseToken = IERC20Upgradeable(_treasury.baseToken());
    uint256 balance = baseToken.balanceOf(address(this));

    return _allocate(balance, revenue);
  }

  /// @inheritdoc IStrategy
  function mintByRevenue(uint256 _baseIn) external override onlyRevenue returns (uint256 _fTokenMinted, uint256 _xTokenMinted) {
    ITreasury _treasury = ITreasury(treasury);
    IERC20Upgradeable baseToken = IERC20Upgradeable(_treasury.baseToken());
    uint256 balance = baseToken.balanceOf(address(this));
    require(balance > _baseIn, "baseIn exceeds balance");

    return _allocate(_baseIn, revenue);
  }

  /*******************************
   * Public Restricted Functions *
   *******************************/

  /// @notice Update the points for allocation.
  /// @param _earn  The point of earn.
  /// @param _platform The new point of platform.
  /// @param _insuranceFund The new point of insurance fund.
  function updateAllocPoint(uint256 _earn, uint256 _platform, uint256 _insuranceFund) external onlyOwner {
    allocPoint = AllocPoint(_earn, _platform, _insuranceFund);
    emit UpdateAllocPoint(_earn, _platform, _insuranceFund);
  }

  /// @notice Change address of staking contract.
  /// @param _staking The new address of staking contract.
  function updateStaking(address _staking) external onlyOwner {
    staking = _staking;
    emit UpdateStaking(staking);
  }

  /// @notice Change address of revenue contract.
  /// @param _revenue The new address of revenue contract.
  function updateRevenue(address _revenue) external onlyOwner {
    revenue = _revenue;
    emit UpdateRevenue(revenue);
  }

  /// @notice Change address of treasury contract.
  /// @param _treasury The new address of treasury contract.
  function updateTreasury(address _treasury) external onlyOwner {
    treasury = _treasury;
    emit UpdateTreasury(treasury);
  }

  /// @notice Change address of platform contract.
  /// @param _platform The new address of platform contract.
  function updatePlatform(address _platform) external onlyOwner {
    platform = _platform;
    emit UpdatePlatform(platform);
  }

  /// @notice Change address of insurance fund contract.
  /// @param _insuranceFund The new address of insurance fund contract.
  function updateInsuranceFund(address _insuranceFund) external onlyOwner {
    insuranceFund = _insuranceFund;
    emit UpdateInsuranceFund(insuranceFund);
  }

  /// @notice Emergency withdraw all assets on the contract.
  /// @return _treasuryAmount The amount of treasury asset.
  /// @return _feeAmount The amount of mint/redeem fee.
  function emergencyWithdraw() external onlyOwner returns (uint256 _treasuryAmount, uint256 _feeAmount) {
    address owner = owner();
    ITreasury _treasury = ITreasury(treasury);
    IERC20Upgradeable baseToken = IERC20Upgradeable(_treasury.baseToken());
    _treasuryAmount = baseToken.balanceOf(treasury);
    _feeAmount = baseToken.balanceOf(address(this));

    if (_treasuryAmount > 0) {
      ITreasury(treasury).transferToStrategy(_treasuryAmount);
      baseToken.transfer(owner, _treasuryAmount);
    }
    if (_feeAmount > 0) baseToken.transfer(owner, _feeAmount);
  }

  /**********************
   * Internal Functions *
   **********************/

  /// @dev Allocate asset.
  /// @param _baseIn The amount of base token supplied.
  /// @param _recipient The address of receiver for fToken and xToken.
  /// @return _fTokenMinted The amount of fToken expected.
  /// @return _xTokenMinted The amount of xToken expected.
  function _allocate(uint256 _baseIn, address _recipient) private returns (uint256 _fTokenMinted, uint256 _xTokenMinted) {
    (uint256 earnAmount, uint256 platformAmount, uint256 insuranceFundAmount) = _computeAllocAmount(_baseIn);
    ITreasury _treasury = ITreasury(treasury);
    IERC20Upgradeable baseToken = IERC20Upgradeable(_treasury.baseToken());

    if (platformAmount > 0) baseToken.transfer(platform, platformAmount);
    if (insuranceFundAmount > 0) baseToken.transfer(insuranceFund, insuranceFundAmount);
    if (earnAmount > 0) {
      IMarket market = IMarket(_treasury.market());
      (uint256 minFTokenMinted, uint256 minXTokenMinted) = _computeMinTokenMinted(earnAmount);

      baseToken.approve(address(market), earnAmount);
      (_fTokenMinted, _xTokenMinted) = market.mint(earnAmount, _recipient, minFTokenMinted, minXTokenMinted);
    } else {
      _fTokenMinted = 0;
      _xTokenMinted = 0;
    }

    emit StrategyMint(_recipient, _baseIn, _fTokenMinted, _xTokenMinted);
  }

  /// @dev Compute all allocation amounts.
  /// @param _totalAmount The amount of supplied.
  /// @return _earnAmount The amount of earn.
  /// @return _platformAmount The amount of platform.
  /// @return _insuranceFundAmount The amount of insurance fund.
  function _computeAllocAmount(uint256 _totalAmount) private view returns (uint256 _earnAmount, uint256 _platformAmount, uint256 _insuranceFundAmount) {
    uint256 _totalAllocPoint = totalAllocPoint();

    _earnAmount = _totalAmount.mul(allocPoint.earn).div(_totalAllocPoint);
    _platformAmount = _totalAmount.mul(allocPoint.platform).div(_totalAllocPoint);
    _insuranceFundAmount = _totalAmount.sub(_earnAmount).sub(_platformAmount);
  }

  /// @notice Compute mintable fToken and xToken according to current collateral ratio.
  /// @param _baseIn The amount of base token supplied.
  /// @return _minFTokenMinted The amount of fToken expected.
  /// @return _minXTokenMinted The amount of xToken expected.
  function _computeMinTokenMinted(uint256 _baseIn) private view returns (uint256 _minFTokenMinted, uint256 _minXTokenMinted) {
    ITreasury _treasury = ITreasury(treasury);
    uint256 baseSupply = _treasury.totalBaseToken();
    uint256 fSupply = IERC20Upgradeable(_treasury.fToken()).totalSupply();
    uint256 xSupply = IERC20Upgradeable(_treasury.xToken()).totalSupply();

    _minFTokenMinted = fSupply.mul(_baseIn).div(baseSupply);
    _minXTokenMinted = xSupply.mul(_baseIn).div(baseSupply);
  }
}