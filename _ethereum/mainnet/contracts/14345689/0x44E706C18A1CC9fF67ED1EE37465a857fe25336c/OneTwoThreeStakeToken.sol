// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IERC20.sol";
import "./ERC20.sol";
import "./SafeMath.sol";

// OneTwoThreeStakeToken is the coolest bar in town. You come in with some 123b, and leave with more! The longer you stay, the more 123b you get.
//
// This contract handles swapping to and from 123s, 123 Swap's staking token.
contract OneTwoThreeStakeToken is ERC20("OneTwoThreeStakeToken", "123s"){
    using SafeMath for uint256;
    IERC20 public bonus;

    // Define the 123b token contract
    constructor(IERC20 _bonus) public {
        bonus = _bonus;
    }

    // Enter the bar. Pay some 123bs. Earn some shares.
    // Locks 123b and mints 123s
    function enter(uint256 _amount) public {
        // Gets the amount of 123b locked in the contract
        uint256 total123b = bonus.balanceOf(address(this));
        // Gets the amount of 123s in existence
        uint256 totalShares = totalSupply();
        // If no 123s exists, mint it 1:1 to the amount put in
        if (totalShares == 0 || total123b == 0) {
            _mint(msg.sender, _amount);
        } 
        // Calculate and mint the amount of 123s the 123b is worth. The ratio will change overtime, as 123s is burned/minted and 123b deposited + gained from fees / withdrawn.
        else {
            uint256 what = _amount.mul(totalShares).div(total123b);
            _mint(msg.sender, what);
        }
        // Lock the 123b in the contract
        bonus.transferFrom(msg.sender, address(this), _amount);
    }

    // Leave the bar. Claim back your 123b.
    // Unlocks the staked + gained 123b and burns 123s
    function leave(uint256 _share) public {
        // Gets the amount of 123s in existence
        uint256 totalShares = totalSupply();
        // Calculates the amount of 123b the 123s is worth
        uint256 what = _share.mul(bonus.balanceOf(address(this))).div(totalShares);
        _burn(msg.sender, _share);
        bonus.transfer(msg.sender, what);
    }
}
