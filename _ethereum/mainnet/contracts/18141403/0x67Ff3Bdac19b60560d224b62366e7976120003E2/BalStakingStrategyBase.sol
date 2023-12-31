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
import "./ITetuLiquidator.sol";

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
  string public constant VERSION = "1.2.1";
  /// @dev 0% buybacks, all should be done on polygon
  ///      Probably we will change it later
  uint256 private constant _BUY_BACK_RATIO = 0;

  address internal constant _BAL_TOKEN = 0xba100000625a3754423978a60c9317c58a424e3D;
  address internal constant _WETH_TOKEN = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
  address internal constant _BALANCER_VAULT = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;

  address internal constant _USDC_TOKEN = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

  ITetuLiquidator internal constant LIQUIDATOR = ITetuLiquidator(0x90351d15F036289BE9b1fd4Cb0e2EeC63a9fF9b0);

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

    // claim usdc rewards
    rtToClaim[0] = IERC20(_USDC_TOKEN);
    IBalLocker(_VE_LOCKER_KEY.getAddress()).claimVeRewards(rtToClaim, address(this));

    uint usdcBalance = IERC20(_USDC_TOKEN).balanceOf(address(this));

    if (usdcBalance != 0) {
      _approveIfNeed(_USDC_TOKEN, address(LIQUIDATOR), usdcBalance);
      LIQUIDATOR.liquidate(_USDC_TOKEN, _WETH_TOKEN, usdcBalance, 5_000);

      uint wethBalance = IERC20(_WETH_TOKEN).balanceOf(address(this));

      if (wethBalance != 0) {
        _approveIfNeed(_WETH_TOKEN, address(LIQUIDATOR), wethBalance);
        LIQUIDATOR.liquidate(_WETH_TOKEN, _BAL_TOKEN, wethBalance, 5_000);

        uint balBalance = IERC20(_BAL_TOKEN).balanceOf(address(this));
        if (balBalance != 0) {
          IERC20(_BAL_TOKEN).safeTransfer(_depositor, balBalance);
        }
      }
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

  //////////////// INTERNAL /////////////////

  /// @dev Swap _tokenIn to _tokenOut using pool identified by _poolId
  function _balancerSwap(bytes32 _poolId, address _tokenIn, address _tokenOut, uint _amountIn) internal {
    if (_amountIn != 0) {
      IBVault.SingleSwap memory singleSwapData = IBVault.SingleSwap({
        poolId: _poolId,
        kind: IBVault.SwapKind.GIVEN_IN,
        assetIn: IAsset(_tokenIn),
        assetOut: IAsset(_tokenOut),
        amount: _amountIn,
        userData: ""
      });

      IBVault.FundManagement memory fundManagementStruct = IBVault.FundManagement({
        sender: address(this),
        fromInternalBalance: false,
        recipient: payable(address(this)),
        toInternalBalance: false
      });

      _approveIfNeed(_tokenIn, _BALANCER_VAULT, _amountIn);
      IBVault(_BALANCER_VAULT).swap(singleSwapData, fundManagementStruct, 1, block.timestamp);
    }
  }

  function _approveIfNeed(address token, address dst, uint amount) internal {
    if (IERC20(token).allowance(address(this), dst) < amount) {
      IERC20(token).safeApprove(dst, 0);
      IERC20(token).safeApprove(dst, type(uint).max);
    }
  }
}
