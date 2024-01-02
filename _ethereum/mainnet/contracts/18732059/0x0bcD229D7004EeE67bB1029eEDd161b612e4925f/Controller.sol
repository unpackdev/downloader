// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC20.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

import "./IController.sol";
import "./ISubStrategy.sol";

contract ethController is IController, Ownable {

    using SafeERC20 for IERC20;

    string public constant version = "3.0";

    // Vault Address
    address public vault;

    // Asset for deposit
    IERC20 public asset;

    address public subStrategy;

    // Withdraw Fee
    uint256 public withdrawFee;

    // Magnifier
    uint256 public constant magnifier = 10000;

    // Treasury Address
    address public treasury;

    event SetVault(address vault);

    event SetTreasury(address treasury);

    event SetWithdrawFee(uint256 withdrawFee);


    constructor(
        address _vault,
        address _subStrategy,
        IERC20 _asset,
        address _treasury
    ) {
        vault = _vault;
        subStrategy = _subStrategy;

        // Address zero for asset means ETH
        asset = _asset;
        treasury = _treasury;

    }

    modifier onlyVault() {
        require(vault == _msgSender(), "ONLY_VAULT");
        _;
    }
    function isSubStrategy(address addr) external view returns(bool){
        return addr == subStrategy;
    }
    /**
        Deposit function is only callable by vault
     */
    function deposit(
        uint256 _amount
    ) external override onlyVault returns (uint256) {
        // Check input amount
        require(_amount > 0, "ZERO AMOUNT");
        uint256 depositAmt = _deposit(_amount);
        return depositAmt;
    }

    /**
        Withdraw requested amount of asset and send to receiver as well as send to treasury
        if default pool has enough asset, withdraw from it. unless loop through SS in the sequence of APY, and try to withdraw
     */
    function withdraw(
        uint256 _amount,
        address _receiver
    ) external override onlyVault returns (uint256 withdrawAmt, uint256 fee) {
        // Check input amount
        require(_amount > 0, "ZERO AMOUNT");

        // Todo: withdraw as much as possible
        withdrawAmt = ISubStrategy(subStrategy).withdraw(_amount);
            // Pay Withdraw Fee to treasury and send rest to user
        fee = (withdrawAmt * withdrawFee) / magnifier;
        if (fee > 0) {
            asset.safeTransferFrom(subStrategy,treasury, fee);
        }

        // Transfer withdrawn token to receiver
        uint256 toReceive = withdrawAmt - fee;
        asset.safeTransferFrom(subStrategy,_receiver, toReceive);
    }

    /**
        Withdrawable amount check
     */
    function withdrawable(
        uint256 _amount
    ) external view returns (uint256 withdrawAmt) {
        if (_amount == 0) return 0;

        withdrawAmt = ISubStrategy(subStrategy).withdrawable(_amount);
    }

    /**
        Query for total assets deposited in all sub strategies
     */
    function totalAssets() external view override returns (uint256) {
        return _totalAssets();
    }

    //////////////////////////////////////////
    //           SET CONFIGURATION          //
    //////////////////////////////////////////

    function setVault(address _vault) external onlyOwner {
        require(_vault != address(0), "INVALID_ADDRESS");
        vault = _vault;

        emit SetVault(vault);
    }

    /**
        Set fee pool address
     */
    function setTreasury(address _treasury) external onlyOwner {
        require(_treasury != address(0), "ZERO_ADDRESS");
        treasury = _treasury;

        emit SetTreasury(treasury);
    }

    /**
        Set withdraw fee
     */
    function setWithdrawFee(uint256 _withdrawFee) external onlyOwner {
        require(_withdrawFee < magnifier, "INVALID_WITHDRAW_FEE");
        withdrawFee = _withdrawFee;

        emit SetWithdrawFee(withdrawFee);
    }


    //////////////////////////////////////////
    //           INTERNAL                   //
    //////////////////////////////////////////
    function _totalAssets() internal view returns (uint256) {
        return ISubStrategy(subStrategy).totalAssets();
    }

    /**
        _deposit is internal function for deposit action, if default option is set, deposit all requested amount to default sub strategy.
        Unless loop through sub strategies regiestered and distribute assets according to the allocpoint of each SS
     */
    function _deposit(uint256 _amount) internal returns (uint256 depositAmt) {
            // Calls deposit function on SubStrategy
        asset.safeTransferFrom(vault, subStrategy, _amount);
        depositAmt = ISubStrategy(subStrategy).deposit(_amount);
    }
}
