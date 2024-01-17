// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./SafeMath.sol";
import "./SafeERC20Upgradeable.sol";
import "./EnumerableSet.sol";
import "./ConfigHelper.sol";
import "./AlloyxConfig.sol";
import "./AdminUpgradeable.sol";
import "./IRibbonLendDesk.sol";
import "./IRibbonPoolMaster.sol";

/**
 * @title RibbonLendDesk
 * @notice NAV or statistics related to assets managed for RibbonLendDesk, the pool masters are contracts in RibbonLend, in here, we take portfolio with USDC as base token
 * @author AlloyX
 */
contract RibbonLendDesk is IRibbonLendDesk, AdminUpgradeable {
  using SafeMath for uint256;
  using ConfigHelper for AlloyxConfig;
  using EnumerableSet for EnumerableSet.AddressSet;
  AlloyxConfig public config;
  EnumerableSet.AddressSet poolMasterAddresses;
  event AlloyxConfigUpdated(address indexed who, address configAddress);

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
   * @notice Update configuration contract address
   */
  function updateConfig() external onlyAdmin isPaused {
    config = AlloyxConfig(config.configAddress());
    emit AlloyxConfigUpdated(msg.sender, address(config));
  }

  /**
   * @notice Get the token balance on one portfolio address
   * @param _address the address of managed portfolio
   */
  function balanceOfPortfolioToken(address _address) external view returns (uint256) {
    IManagedPortfolio managedPortfolio = IManagedPortfolio(_address);
    return managedPortfolio.balanceOf(address(this));
  }

  /**
   * @notice Get the Usdc value of the Clear Pool wallet
   */
  function getRibbonLendWalletUsdcValue() external view override returns (uint256) {
    uint256 length = poolMasterAddresses.length();
    uint256 allBalance = 0;
    for (uint256 i = 0; i < length; i++) {
      uint256 balance = getRibbonLendUsdcValueOfPoolMaster(poolMasterAddresses.at(i));
      allBalance += balance;
    }
    return allBalance;
  }

  /**
   * @notice Get the Usdc value of the Clear Pool wallet on one pool master address
   * @param _address the address of pool master
   */
  function getRibbonLendUsdcValueOfPoolMaster(address _address) public view returns (uint256) {
    IRibbonPoolMaster poolMaster = IRibbonPoolMaster(_address);
    uint256 exchangeRate = poolMaster.getCurrentExchangeRate();
    uint256 balanceOfWallet = poolMaster.balanceOf(address(this));
    return balanceOfWallet.mul(exchangeRate).div(1e18);
  }

  /**
   * @notice Add pool master address to the list
   * @param _address the address of pool master
   */
  function addPoolMasterAddress(address _address) external onlyAdmin {
    require(!poolMasterAddresses.contains(_address), "the address already inside the list");
    IRibbonPoolMaster poolMaster = IRibbonPoolMaster(_address);
    require(
      poolMaster.balanceOf(address(this)) > 0,
      "the balance of the desk on the pool master should not be 0 before adding"
    );
    poolMasterAddresses.add(_address);
  }

  /**
   * @notice Remove pool master address to the list
   * @param _address the address of pool master
   */
  function removePoolMasterAddress(address _address) external onlyAdmin {
    require(poolMasterAddresses.contains(_address), "the address should be inside the list");
    IRibbonPoolMaster poolMaster = IRibbonPoolMaster(_address);
    require(
      poolMaster.balanceOf(address(this)) == 0,
      "the balance of the desk on the pool master should be 0 before removing"
    );
    poolMasterAddresses.remove(_address);
  }

  /**
   * @notice Deposit treasury USDC to RibbonLend pool master
   * @param _address the address of pool master
   * @param _amount the amount to deposit
   */
  function provide(address _address, uint256 _amount) external onlyAdmin {
    IRibbonPoolMaster poolMaster = IRibbonPoolMaster(_address);
    config.getTreasury().transferERC20(config.usdcAddress(), address(this), _amount);
    config.getUSDC().approve(_address, _amount);
    poolMaster.provide(_amount, address(this));
    if (!poolMasterAddresses.contains(_address)) {
      poolMasterAddresses.add(_address);
    }
  }

  /**
   * @notice Withdraw USDC from RibbonLend pool master
   * @param _address the address of pool master
   * @param _amount the amount to withdraw in pool master tokens
   */
  function redeem(address _address, uint256 _amount) external onlyAdmin returns (uint256) {
    IRibbonPoolMaster poolMaster = IRibbonPoolMaster(_address);
    poolMaster.redeem(_amount);
    uint256 usdcAmount = config.getUSDC().balanceOf(address(this));
    config.getUSDC().transfer(config.treasuryAddress(), usdcAmount);
    if (poolMaster.balanceOf(address(this)) == 0) {
      poolMasterAddresses.remove(_address);
    }
    return usdcAmount;
  }
}
