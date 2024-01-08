//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";

import "./IFeeManager.sol";
import "./console.sol";

contract FeeManager is IFeeManager, Ownable{

    uint feeRatio;
    using SafeERC20 for IERC20;
    using SafeMath for uint;

    constructor(uint _feeRatio) Ownable() public{
        setFeeRatio(_feeRatio);
    }

    function setFeeRatio(uint _feeRatio) public onlyOwner{
        feeRatio = _feeRatio;
    }

    function withdraw(address token, address to, uint amount) public onlyOwner{
        if (token == address(0))
            to.call{value: amount}("");
        else
            IERC20(token).safeTransfer(to, amount);
    }

    function getFeeFromGrossAmount(address sender, uint amount) public view returns (uint){
        if (sender == owner())
            return 0;
        return amount.mul(feeRatio).div(10000);
    }

    function getGrossAmountFromNetAmount(address sender, uint amount) public view returns (uint){
        if (sender == owner())
            return amount;
        return amount.mul(10000).div(10000-feeRatio);
    }

    function collectFee(address sender, address debtToken, uint baseAmount) external override {
        uint fee = getFeeFromGrossAmount(sender, baseAmount);
        if (fee>0)
            IERC20(debtToken).safeTransferFrom(msg.sender, address(this), fee);
    }

}