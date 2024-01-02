// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./Ownable.sol";

contract StaxTeamVesting is Ownable {
    using SafeMath for uint256;
    uint private _deadline;
    uint constant private _ONEDAY = 1 days;
    IERC20 public token = IERC20(0x5a87598aA7FB765EfBfe1042e792F2A5eF46F27b);
    uint256 public amount;

    constructor() {
        _deadline = block.timestamp + (30 * _ONEDAY);
        amount = token.totalSupply().div(10).div(20);
    }

    function balance() external view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function deadline() external view returns (uint) {
        return _deadline;
    }

    function withdrawTokens() external onlyOwner returns (bool) {
        require(block.timestamp > _deadline, "Vesting: Not Yet");
        _deadline = block.timestamp + (30 * _ONEDAY);
        uint256 _amount = amount;
        if (token.balanceOf(address(this)) < amount) {
            _amount = token.balanceOf(address(this));
        }
        token.transfer(_msgSender(), _amount);
        return true;
    }
}