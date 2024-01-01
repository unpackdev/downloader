// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./SafeMath.sol";
import "./SafeERC20Upgradeable.sol";
import "./ERC721HolderUpgradeable.sol";
import "./EnumerableSet.sol";
import "./ConfigHelper.sol";
import "./AlloyxConfig.sol";
import "./AdminUpgradeable.sol";
import "./IFluxDesk.sol";

/**
 * @title FluxDesk
 * @notice All transactions or statistics related to Flux
 * @author AlloyX
 */
contract FluxDesk is IFluxDesk, AdminUpgradeable, ERC721HolderUpgradeable {
  using SafeMath for uint256;
  using ConfigHelper for AlloyxConfig;
  using SafeERC20Upgradeable for IERC20Upgradeable;
  using SafeERC20Upgradeable for IERC20Token;
  using EnumerableSet for EnumerableSet.UintSet;

  AlloyxConfig public config;

  // Alloyx Pool => Flux Amount
  mapping(address => uint256) internal vaultToFlux;

  event Mint(address _vaultAddress, uint256 _amount);
  event Redeem(address _vaultAddress, uint256 _amount);
  event AlloyxConfigUpdated(address indexed who, address configAddress);

  /**
   * @notice Initialize the contract
   * @param _configAddress the address of configuration contract
   */
  function initialize(address _configAddress) external initializer {
    __AdminUpgradeable_init(msg.sender);
    config = AlloyxConfig(_configAddress);
  }

  /**
   * @notice If user operation is paused
   */
  modifier isPaused() {
    require(config.isPaused(), "all user operations should be paused");
    _;
  }

  /**
   * @notice If the transaction is triggered from operator contract
   */
  modifier onlyOperator() {
    require(msg.sender == config.operatorAddress(), "only operator");
    _;
  }

  /**
   * @notice Update configuration contract address
   */
  function updateConfig() external onlyAdmin isPaused {
    config = AlloyxConfig(config.configAddress());
    emit AlloyxConfigUpdated(msg.sender, address(config));
  }

  /**
   * @notice Purchase Flux
   * @param _vaultAddress the vault address
   * @param _amount the amount of usdc to purchase by
   */
  function mint(address _vaultAddress, uint256 _amount) external override onlyOperator {
    config.getUSDC().approve(config.fluxTokenAddress(), _amount);
    uint256 preShare = config.getFluxToken().balanceOf(address(this));
    config.getFluxToken().mint(_amount);
    uint256 postShare = config.getFluxToken().balanceOf(address(this));
    vaultToFlux[_vaultAddress] = vaultToFlux[_vaultAddress].add(postShare.sub(preShare));
    emit Mint(_vaultAddress, postShare.sub(preShare));
  }

  /**
   * @notice Redeem FLUX
   * @param _vaultAddress the vault address
   * @param _amount the amount of FLUX to sell
   */
  function redeem(address _vaultAddress, uint256 _amount) external override onlyOperator {
    require(vaultToFlux[_vaultAddress] >= _amount, "vault does not have sufficient FLUX");
    uint256 preUsdc = config.getUSDC().balanceOf(address(this));
    config.getFluxToken().redeem(_amount);
    uint256 postUsdc = config.getUSDC().balanceOf(address(this));
    config.getUSDC().safeTransfer(_vaultAddress, postUsdc.sub(preUsdc));
    vaultToFlux[_vaultAddress] = vaultToFlux[_vaultAddress].sub(_amount);
    emit Redeem(_vaultAddress, _amount);
  }

  /**
   * @notice Fidu Value in Vault in term of USDC
   * @param _vaultAddress the pool address of which we calculate the balance
   */
  function getFluxBalanceInUsdc(address _vaultAddress) public view override returns (uint256) {
    return vaultToFlux[_vaultAddress].mul(config.getFluxToken().exchangeRateStored()).div(10 ** 18);
  }

  /**
   * @notice Redeem FLUX from Vault directly
   * @param _usdcAmount the amount of USDC to sell
   */
  function redeemUsdc(uint256 _usdcAmount) external override returns (uint256) {
    address _vaultAddress = msg.sender;
    uint256 _amount = _usdcAmount.mul(10 ** 18).div(config.getFluxToken().exchangeRateStored());
    require(vaultToFlux[_vaultAddress] >= _amount, "vault does not have sufficient FLUX tokens");
    uint256 preUsdc = config.getUSDC().balanceOf(address(this));
    config.getFluxToken().redeem(_amount);
    uint256 postUsdc = config.getUSDC().balanceOf(address(this));
    config.getUSDC().safeTransfer(_vaultAddress, postUsdc.sub(preUsdc));
    vaultToFlux[_vaultAddress] = vaultToFlux[_vaultAddress].sub(_amount);
    emit Redeem(_vaultAddress, _amount);
    return postUsdc.sub(preUsdc);
  }

  /**
   * @notice Flux Balance in Vault in term
   * @param _vaultAddress the pool address
   */
  function getFluxBalance(address _vaultAddress) external view override returns (uint256) {
    return vaultToFlux[_vaultAddress];
  }
}
