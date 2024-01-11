// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

import "./ProxyStrategyBase.sol";
import "./IBalLocker.sol";
import "./SlotsLib.sol";
import "./IBVault.sol";

/// @title Base contract for BAL stake into veBAL pool
/// @author belbix
abstract contract BalStakingStrategyBase is ProxyStrategyBase {
  using SafeERC20 for IERC20;
  using SlotsLib for bytes32;

  // --------------------- CONSTANTS -------------------------------
  /// @notice Strategy type for statistical purposes
  string public constant override STRATEGY_NAME = "BalStakingStrategyBase";
  /// @notice Version of the contract
  /// @dev Should be incremented when contract changed
  string public constant VERSION = "1.1.0";
  /// @dev 0% buybacks, all should be done on polygon
  ///      Probably we will change it later
  uint256 private constant _BUY_BACK_RATIO = 0;

  address private constant _BAL_TOKEN = 0xba100000625a3754423978a60c9317c58a424e3D;
  address private constant _WETH_TOKEN = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
  address private constant _BB_USD_TOKEN = 0x7B50775383d3D6f0215A8F290f2C9e2eEBBEceb2;
  address private constant _BALANCER_VAULT = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
  bytes32 private constant _WETH_BB_USD_POOL_ID = 0x70b7d3b3209a59fb0400e17f67f3ee8c37363f4900020000000000000000018f;
  bytes32 private constant _WETH_BAL_POOL_ID = 0x5c6ee304399dbdb9c8ef030ab642b10820db8f56000200000000000000000014;

  bytes32 internal constant _VE_LOCKER_KEY = bytes32(uint256(keccak256("s.ve_locker")) - 1);
  bytes32 internal constant _DEPOSITOR_KEY = bytes32(uint256(keccak256("s.depositor")) - 1);


  /// @notice Initialize contract after setup it as proxy implementation
  function initializeStrategy(
    address controller_,
    address underlying_,
    address vault_,
    address[] memory rewardTokens_,
    address veLocker_,
    address depositor_
  ) public initializer {
    _VE_LOCKER_KEY.set(veLocker_);
    _DEPOSITOR_KEY.set(depositor_);
    ProxyStrategyBase.initializeStrategyBase(
      controller_,
      underlying_,
      vault_,
      rewardTokens_,
      _BUY_BACK_RATIO
    );

    IERC20(underlying_).safeApprove(veLocker_, type(uint256).max);
  }


  // --------------------------------------------

  /// @dev Contract for bridge assets between networks
  function depositor() external view returns (address){
    return _DEPOSITOR_KEY.getAddress();
  }


  function veLocker() external view returns (address) {
    return _VE_LOCKER_KEY.getAddress();
  }

  /// @dev Set locker if empty
  function setVeLocker(address newVeLocker) external {
    require(_VE_LOCKER_KEY.getAddress() == address(0), "Not zero locker");
    _VE_LOCKER_KEY.set(newVeLocker);
    IERC20(_underlying()).safeApprove(newVeLocker, type(uint256).max);
  }

  // --------------------------------------------

  /// @notice Return only pool balance. Assume that we ALWAYS invest on vault deposit action
  function investedUnderlyingBalance() external override view returns (uint) {
    return _rewardPoolBalance();
  }

  /// @dev Returns underlying balance in the pool
  function _rewardPoolBalance() internal override view returns (uint256) {
    return IBalLocker(_VE_LOCKER_KEY.getAddress()).investedUnderlyingBalance();
  }

  /// @dev Collect profit and do something useful with them
  function doHardWork() external override {
    address _depositor = _DEPOSITOR_KEY.getAddress();
    require(msg.sender == _depositor, "Not depositor");

    IERC20[] memory rtToClaim = new IERC20[](1);

    // claim BAL rewards
    rtToClaim[0] = IERC20(_BAL_TOKEN);
    IBalLocker(_VE_LOCKER_KEY.getAddress()).claimVeRewards(rtToClaim, _depositor);

    // claim bb-usd rewards
    rtToClaim[0] = IERC20(_BB_USD_TOKEN);
    IBalLocker(_VE_LOCKER_KEY.getAddress()).claimVeRewards(rtToClaim, address(this));

    uint amount = IERC20(_BB_USD_TOKEN).balanceOf(address(this));

    if (amount != 0) {

      // bbUSD token already have max allowance for balancer vault

      IBVault.BatchSwapStep[] memory swaps = new IBVault.BatchSwapStep[](2);

      IAsset[] memory assets = new IAsset[](3);
      assets[0] = IAsset(_BB_USD_TOKEN);
      assets[1] = IAsset(_WETH_TOKEN);
      assets[2] = IAsset(_BAL_TOKEN);

      IBVault.FundManagement memory fundManagement = IBVault.FundManagement({
      sender : address(this),
      fromInternalBalance : false,
      recipient : payable (_depositor),
      toInternalBalance : false
      });

      int256[] memory limits = new int256[](3);
      limits[0] = type(int256).max;
      limits[1] = type(int256).max;
      limits[2] = type(int256).max;

      // set first step
      swaps[0] = IBVault.BatchSwapStep({
      poolId : _WETH_BB_USD_POOL_ID,
      assetInIndex : 0,
      assetOutIndex : 1,
      amount : amount,
      userData : ""
      });

      // set second step
      swaps[1] = IBVault.BatchSwapStep({
      poolId : _WETH_BAL_POOL_ID,
      assetInIndex : 1,
      assetOutIndex : 2,
      amount : 0,
      userData : ""
      });

      IBVault(_BALANCER_VAULT).batchSwap(
        IBVault.SwapKind.GIVEN_IN,
        swaps,
        assets,
        fundManagement,
        limits,
        block.timestamp
      );

    }
  }

  /// @dev Stake underlying to the pool with maximum lock period
  function depositToPool(uint256 amount) internal override {
    if (amount > 0) {
      address locker = _VE_LOCKER_KEY.getAddress();
      IERC20(_underlying()).safeTransfer(locker, amount);
      IBalLocker(locker).depositVe(amount);
    }
  }

  /// @dev We will not able to withdraw from the pool
  function withdrawAndClaimFromPool(uint256) internal pure override {
    revert("BSS: Withdraw forbidden");
  }

  /// @dev Curve implementation does not have emergency withdraw
  function emergencyWithdrawFromPool() internal pure override {
    revert("BSS: Withdraw forbidden");
  }

  /// @dev No claimable tokens
  function readyToClaim() external view override returns (uint256[] memory) {
    uint256[] memory toClaim = new uint256[](_rewardTokens.length);
    return toClaim;
  }

  /// @dev Return full amount of staked tokens
  function poolTotalAmount() external view override returns (uint256) {
    return IERC20(_underlying()).balanceOf(IBalLocker(_VE_LOCKER_KEY.getAddress()).VE_BAL());
  }

  /// @dev Platform name for statistical purposes
  /// @return Platform enum index
  function platform() external override pure returns (Platform) {
    return Platform.BALANCER;
  }

  function liquidateReward() internal pure override {
    // noop
  }

}
