// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";

contract Migrate is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    address public token;
    address public migrateToken;
    uint256 public rate;
    
    constructor(address _token, address _migrateToken, uint256 _rate) public {
        token = _token;
        migrateToken = _migrateToken;
        rate = _rate;
    }

    function setToken(address _token, address _migrateToken) public onlyOwner {
        token = _token;
        migrateToken = _migrateToken;
    }
    
    function withdrawToken(uint256 _amount) public onlyOwner {
        require(IERC20(migrateToken).balanceOf(address(this)) >= _amount, "Balance not enough.");
        IERC20(migrateToken).safeTransfer( msg.sender, _amount);
    }

    function setRate(uint256 _rate) public onlyOwner {
        rate = _rate;
    }
    
    function migrate(uint256 _amount) public {
        uint256 amountOut = _amount.add(_amount.mul(rate).div(10000));
        require(IERC20(token).balanceOf(msg.sender) >= _amount, "Your balance not enough.");
        require(IERC20(migrateToken).balanceOf(address(this)) >= amountOut, "Balance not enough.");
        IERC20(token).safeTransferFrom(msg.sender, address(this), _amount);
        IERC20(migrateToken).safeTransfer(msg.sender, amountOut);
    }

}