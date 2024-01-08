// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma abicoder v2;

import "./SafeMath.sol";
import "./IERC20.sol";


contract UniverseStaking {

    using SafeMath for uint256;

    //token => user => balance
    mapping(address=>mapping(address=>uint256)) _balances;

    /* ========== STAKING FUNCTION ========== */

    function balanceOf(address tokenAddress, address user) external view returns(uint256){
        return _balances[tokenAddress][user];
    }

    function staking(address tokenAddress, uint256 amount) external {
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);
        _balances[tokenAddress][msg.sender] = _balances[tokenAddress][msg.sender].add(amount);
        // EVENT
        emit Staking(msg.sender, tokenAddress, amount);
    }

    function _amountUpdate(address tokenAddress, uint256 amount) internal returns(uint256) {
        uint256 balance = _balances[tokenAddress][msg.sender];
        if(amount > balance){
            amount = balance;
        }
        require(amount > 0, "unStaking ZERO");
        _balances[tokenAddress][msg.sender] = balance.sub(amount);
        return amount;
    }

    function unStaking(address tokenAddress, uint256 amount) external {
        amount = _amountUpdate(tokenAddress, amount);
        IERC20(tokenAddress).transfer(msg.sender, amount);
        // EVENT
        emit UnStaking(msg.sender, tokenAddress, amount);
    }


    /* ========== EVENT ========== */

    event Staking(
        address indexed user,
        address tokenAddress,
        uint256 amount
    );

    event UnStaking(
        address indexed user,
        address tokenAddress,
        uint256 amount
    );

}
