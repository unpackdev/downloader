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
import "./BasicFund.sol";
pragma abicoder v2;
/// @title Fund Contract - The implmentation of fund contract
/// @notice This contract extends Basic Fund and defines the join and redeem activities
contract Fund is BasicFund {

    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using SafeMathExtends for uint256;
    using Address for address;

    event PoolJoined(address indexed investor, uint256 amount);
    event PoolExited(address indexed investor, uint256 amount);

    /// @notice deny contract
    modifier notAllowContract() {
        require(!address(msg.sender).isContract(), "is contract ");
        _;
    }

    constructor(
        string memory name,
        string memory symbol
    ) BasicFund(name, symbol){

    }

    /// @notice Bind join and redeem address with asset management contract
    /// @dev Make the accuracy of the fund consistent with the accuracy of the bound token; it can only be bound once and cannot be modified
    /// @param token Join and redeem fund token address
    /// @param am Asset managemeent address
    function bind(address token, address am) external {
        require(!SmartPoolStorage.load().bind, "already bind");
        _decimals = IERC20Metadata(token).decimals();
        SmartPoolStorage.load().token = token;
        SmartPoolStorage.load().am = am;
        SmartPoolStorage.load().bind = true;
        SmartPoolStorage.load().suspend = false;
        SmartPoolStorage.load().allowJoin = true;
        SmartPoolStorage.load().allowExit = true;
    }

    /// @notice Subscript fund
    /// @dev When subscribing to the fund, fee will be collected, and contract access is not allowed
    /// @param amount Subscription amount
    function joinPool(uint256 amount) external isAllowJoin notAllowContract {
        address investor = msg.sender;
        require(amount <= ioToken().balanceOf(investor) && amount > 0, "Insufficient balance");
        uint256 fundAmount = convertToFund(amount);
        //take management fee
        takeOutstandingManagementFee();
        //take join fee
        uint256 fee = _takeJoinFee(investor, fundAmount);
        uint256 realFundAmount = fundAmount.sub(fee);
        _mint(investor, realFundAmount);
        ioToken().safeTransferFrom(investor, AM(), amount);
        emit PoolJoined(investor, realFundAmount);
    }

    /// @notice Redeem fund
    /// @dev When the fund is redeemed, fees will be collected, and contract access is not allowed
    /// @param amount Redeem amount
    function exitPool(uint256 amount) external isAllowExit notAllowContract {
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

    /// @notice Redeem the underlying assets of the fund
    /// @dev When the fund is redeemed, fees will be collected, and contract access is not allowed
    /// @param amount Redeem amount
    function exitPoolOfUnderlying(uint256 amount) external isAllowExit notAllowContract {
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

    /// @notice Fund token address for joining and redeeming
    /// @dev This is address is created when the fund is first created.
    /// @return Fund token address
    function ioToken() public view returns (IERC20){
        return IERC20(SmartPoolStorage.load().token);
    }

    /// @notice Fund mangement contract address
    /// @dev The fund management contract address is bind to the fund when the fund is created
    /// @return Fund management contract address
    function AM() public view returns (address){
        return SmartPoolStorage.load().am;
    }


    /// @notice Convert fund amount to cash amount
    /// @dev This converts the user fund amount to cash amount when a user redeems the fund
    /// @param fundAmount Redeem fund amount
    /// @return Cash amount
    function convertToCash(uint256 fundAmount) public virtual override view returns (uint256){
        uint256 cash = 0;
        uint256 totalSupply = totalSupply();
        uint256 _assets = assets();
        if (totalSupply == 0 || _assets == 0) {
            cash = 0;
        } else {
            cash = _assets.mul(fundAmount).div(totalSupply);
        }
        return cash;
    }

    /// @notice Convert cash amount to fund amount
    /// @dev This converts cash amount to fund amount when a user buys the fund
    /// @param cashAmount Join cash amount
    /// @return Fund amount
    function convertToFund(uint256 cashAmount) public virtual override view returns (uint256){
        uint256 totalSupply = totalSupply();
        uint256 _assets = assets();
        if (totalSupply == 0 || _assets == 0) {
            return cashAmount;
        } else {
            return cashAmount.mul(totalSupply).div(_assets);
        }
    }

    /// @notice Fund total asset
    /// @dev This calculates fund net worth or AUM
    /// @return Fund total asset
    function assets() public view returns (uint256){
        return IAssetManager(AM()).assets();
    }
}
