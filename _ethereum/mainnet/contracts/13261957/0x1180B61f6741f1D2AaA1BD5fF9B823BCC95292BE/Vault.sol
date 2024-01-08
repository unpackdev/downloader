// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";

import "./IAssetManager.sol";
import "./IERC20Metadata.sol";

import "./SafeMathExtends.sol";
import "./SmartPoolStorage.sol";
import "./BasicVault.sol";
pragma abicoder v2;
/// @title Vault Contract - The implmentation of vault contract
/// @notice This contract extends Basic Vault and defines the join and redeem activities
contract Vault is BasicVault {

    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using SafeMathExtends for uint256;
    using Address for address;

    event PoolJoined(address indexed investor, uint256 amount);
    event PoolExited(address indexed investor, uint256 amount);

    /// @notice deny contract
    modifier notAllowContract() {
        require(!address(msg.sender).isContract(), "is contract");
        _;
    }
    /// @notice not in lup
    modifier notInLup() {
        bool inLup = block.timestamp <= lup();
        require(!inLup, "in lup");
        _;
    }

    constructor(
        string memory name,
        string memory symbol
    ) BasicVault(name, symbol){

    }

    /// @notice lock-up period
    function lup() public view returns (uint256){
        return SmartPoolStorage.load().lup;
    }

    /// @notice lock-up period
    /// @param _lup period value
    function setLup(uint256 _lup) external onlyAdminOrGovernance {
        SmartPoolStorage.load().lup = _lup;
    }

    /// @notice Bind join and redeem address with asset management contract
    /// @dev Make the accuracy of the vault consistent with the accuracy of the bound token; it can only be bound once and cannot be modified
    /// @param token Join and redeem vault token address
    /// @param am Asset managemeent address
    function bind(
        string memory name,
        string memory symbol,
        address token,
        address am) external onlyGovernance {
        _name = name;
        _symbol = symbol;
        _decimals = IERC20Metadata(token).decimals();
        SmartPoolStorage.load().token = token;
        SmartPoolStorage.load().am = am;
        SmartPoolStorage.load().bind = true;
        SmartPoolStorage.load().suspend = false;
        SmartPoolStorage.load().allowJoin = true;
        SmartPoolStorage.load().allowExit = true;
    }

    /// @notice Subscript vault
    /// @dev When subscribing to the vault, fee will be collected, and contract access is not allowed
    /// @param amount Subscription amount
    function joinPool(uint256 amount) external isAllowJoin notAllowContract {
        address investor = msg.sender;
        require(amount <= ioToken().balanceOf(investor) && amount > 0, "Insufficient balance");
        uint256 vaultAmount = convertToShare(amount);
        //take management fee
        takeOutstandingManagementFee();
        //take join fee
        uint256 fee = _takeJoinFee(investor, vaultAmount);
        uint256 realVaultAmount = vaultAmount.sub(fee);
        _mint(investor, realVaultAmount);
        ioToken().safeTransferFrom(investor, AM(), amount);
        emit PoolJoined(investor, realVaultAmount);
    }

    /// @notice Redeem vault
    /// @dev When the vault is redeemed, fees will be collected, and contract access is not allowed
    /// @param amount Redeem amount
    function exitPool(uint256 amount) external isAllowExit notInLup notAllowContract {
        address investor = msg.sender;
        require(balanceOf(investor) >= amount && amount > 0, "Insufficient balance");
        //take exit fee
        uint256 exitFee = _takeExitFee(investor, amount);
        uint256 exitAmount = amount.sub(exitFee);
        //take performance fee
        takeOutstandingPerformanceFee(investor);
        //replace exitAmount
        uint256 balance = balanceOf(investor);
        exitAmount = balance < exitAmount ? balance : exitAmount;
        uint256 scale = exitAmount.bdiv(totalSupply());
        uint256 cashAmount = convertToCash(exitAmount);
        //take management fee
        takeOutstandingManagementFee();
        // withdraw cash
        IAssetManager(AM()).withdraw(investor, cashAmount, scale);
        _burn(investor, exitAmount);
        emit PoolExited(investor, exitAmount);
    }

    /// @notice Redeem the underlying assets of the vault
    /// @dev When the vault is redeemed, fees will be collected, and contract access is not allowed
    /// @param amount Redeem amount
    function exitPoolOfUnderlying(uint256 amount) external isAllowExit notInLup notAllowContract {
        address investor = msg.sender;
        require(balanceOf(investor) >= amount && amount > 0, "Insufficient balance");
        //take exit fee
        uint256 exitFee = _takeExitFee(investor, amount);
        uint256 exitAmount = amount.sub(exitFee);
        //take performance fee
        takeOutstandingPerformanceFee(investor);
        //replace exitAmount
        uint256 balance = balanceOf(investor);
        exitAmount = balance < exitAmount ? balance : exitAmount;
        uint256 scale = exitAmount.bdiv(totalSupply());
        //take management fee
        takeOutstandingManagementFee();
        //harvest underlying
        IAssetManager(AM()).withdrawOfUnderlying(investor, scale);
        _burn(investor, exitAmount);
        emit PoolExited(investor, exitAmount);
    }

    /// @notice Vault token address for joining and redeeming
    /// @dev This is address is created when the vault is first created.
    /// @return Vault token address
    function ioToken() public view returns (IERC20){
        return IERC20(SmartPoolStorage.load().token);
    }

    /// @notice Vault mangement contract address
    /// @dev The vault management contract address is bind to the vault when the vault is created
    /// @return Vault management contract address
    function AM() public view returns (address){
        return SmartPoolStorage.load().am;
    }


    /// @notice Convert vault amount to cash amount
    /// @dev This converts the user vault amount to cash amount when a user redeems the vault
    /// @param vaultAmount Redeem vault amount
    /// @return Cash amount
    function convertToCash(uint256 vaultAmount) public virtual override view returns (uint256){
        uint256 cash = 0;
        uint256 totalSupply = totalSupply();
        uint256 _assets = assets();
        if (totalSupply == 0 || _assets == 0) {
            cash = 0;
        } else {
            cash = _assets.mul(vaultAmount).div(totalSupply);
        }
        return cash;
    }

    /// @notice Convert cash amount to share amount
    /// @dev This converts cash amount to share amount when a user buys the vault
    /// @param cashAmount Join cash amount
    /// @return share amount
    function convertToShare(uint256 cashAmount) public virtual override view returns (uint256){
        uint256 totalSupply = totalSupply();
        uint256 _assets = assets();
        if (totalSupply == 0 || _assets == 0) {
            return cashAmount;
        } else {
            return cashAmount.mul(totalSupply).div(_assets);
        }
    }

    /// @notice Vault total asset
    /// @dev This calculates vault net worth or AUM
    /// @return Vault total asset
    function assets() public view returns (uint256){
        return IAssetManager(AM()).assets();
    }
}
