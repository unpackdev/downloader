// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC20.sol";
import "./IERC20.sol";

import "./IController.sol";
import "./ISubStrategy.sol";
import "./TransferHelper.sol";

contract ethController is IController, Ownable, ReentrancyGuard {

    string public constant version = "3.0";

    // Vault Address
    address public vault;

    // Asset for deposit
    ERC20 public asset;

    // WETH address
    address public weth;

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
        //ERC20 _asset,
        address _treasury,
        address _weth
    ) {
        vault = _vault;
        subStrategy = _subStrategy;

        // Address zero for asset means ETH
        //asset = _asset;
        treasury = _treasury;

        weth = _weth;
    }

    receive() external payable {}

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

        if (withdrawAmt > 0) {
            require(
                address(this).balance >= withdrawAmt,
                "INVALID_WITHDRAWN_AMOUNT"
            );

            // Pay Withdraw Fee to treasury and send rest to user
            fee = (withdrawAmt * withdrawFee) / magnifier;
            if (fee > 0) {
                TransferHelper.safeTransferETH(treasury, fee);
            }

            // Transfer withdrawn token to receiver
            uint256 toReceive = withdrawAmt - fee;
            TransferHelper.safeTransferETH(_receiver, toReceive);
        }
    }

    /**
        Withdrawable amount check
     */
    function withdrawable(
        uint256 _amount
    ) public view returns (uint256 withdrawAmt) {
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

    function setVault(address _vault) public onlyOwner {
        require(_vault != address(0), "INVALID_ADDRESS");
        vault = _vault;

        emit SetVault(vault);
    }

    /**
        Set fee pool address
     */
    function setTreasury(address _treasury) public onlyOwner {
        require(_treasury != address(0), "ZERO_ADDRESS");
        treasury = _treasury;

        emit SetTreasury(treasury);
    }

    /**
        Set withdraw fee
     */
    function setWithdrawFee(uint256 _withdrawFee) public onlyOwner {
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

    function getBalance(
        address _asset,
        address _account
    ) internal view returns (uint256) {
        if (address(_asset) == address(0) || address(_asset) == weth)
            return address(_account).balance;
        else return IERC20(_asset).balanceOf(_account);
    }

    /**
        _deposit is internal function for deposit action, if default option is set, deposit all requested amount to default sub strategy.
        Unless loop through sub strategies regiestered and distribute assets according to the allocpoint of each SS
     */
    function _deposit(uint256 _amount) internal returns (uint256 depositAmt) {
            // Transfer asset to substrategy
        TransferHelper.safeTransferETH(subStrategy,_amount);

            // Calls deposit function on SubStrategy
        depositAmt = ISubStrategy(subStrategy).deposit(_amount);
    }
}
