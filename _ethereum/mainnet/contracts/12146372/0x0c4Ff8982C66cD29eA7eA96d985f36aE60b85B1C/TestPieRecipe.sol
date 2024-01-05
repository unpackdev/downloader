// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;

import "./SafeMath.sol";
import "./IERC20.sol";

import "./PieRecipe.sol";

contract TestPieRecipe {
    using SafeMath for uint256;
    mapping(address => uint256) private balance;

    uint256 public calcToPieAmount;

    function toPie(address _pie, uint256 _poolAmount) public payable {
        IERC20 pie = IERC20(_pie);
        uint256 amount = calcToPie(_pie, _poolAmount);
        require(msg.value == amount, "Amount ETH too low");
        pie.transfer(msg.sender, _poolAmount);
    }

    function testSetCalcToPieAmount(uint256 _amount) external {
        calcToPieAmount = _amount;
    }

    function calcToPie(address _pie, uint256 _poolAmount)
        public
        view
        returns (uint256)
    {
        return calcToPieAmount;
    }
}
