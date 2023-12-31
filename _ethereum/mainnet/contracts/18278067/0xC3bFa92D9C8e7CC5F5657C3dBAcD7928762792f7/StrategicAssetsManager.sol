// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./IERC20.sol";
import "./Initializable.sol";
import "./SafeERC20.sol";
import "./AaveGovernanceV2.sol";
import "./AaveV3Ethereum.sol";

import "./LSDLiquidityGaugeManager.sol";
import "./VeTokenManager.sol";
import "./VlTokenManager.sol";

/// @author Llama
contract StrategicAssetsManager is
  Initializable,
  LSDLiquidityGaugeManager,
  VeTokenManager,
  VlTokenManager
{
  using SafeERC20 for IERC20;

  event WithdrawalERC20(address indexed _token, uint256 _amount);

  /// @notice Initialize function
  function initialize() external initializer {
    _transferOwnership(AaveGovernanceV2.SHORT_EXECUTOR);
    _updateGuardian(0x205e795336610f5131Be52F09218AF19f0f3eC60);
    spaceIdBalancer = 'balancer.eth';
    gaugeControllerBalancer = 0xC128468b7Ce63eA702C1f104D55A2566b13D3ABD;
    lockDurationVEBAL = 365 days;
  }

  /// @notice Withdraw a specified amount of ERC20 token to the Aave Collector
  /// @param token The address of the ERC20 token to withdraw
  /// @param amount The amount of token to withdraw
  function withdrawERC20(address token, uint256 amount) external onlyOwner {
    IERC20(token).safeTransfer(address(AaveV3Ethereum.COLLECTOR), amount);
    emit WithdrawalERC20(token, amount);
  }
}
