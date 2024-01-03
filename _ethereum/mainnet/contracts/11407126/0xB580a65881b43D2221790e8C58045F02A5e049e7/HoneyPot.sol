pragma solidity 0.6.12;

import "./IERC20.sol";
import "./ERC20.sol";
import "./SafeMath.sol";

// HoneyPot is the coolest bar in town. You come in with some Honey, and leave with more! The longer you stay, the more Honey you get.
//
// This contract handles swapping to and from xHoney, HoneySwap's staking token.
contract HoneyPot is ERC20("HoneyPot", "xHONEY"){
    using SafeMath for uint256;
    IERC20 public honey;

    // Define the Honey token contract
    constructor(IERC20 _honey) public {
        honey = _honey;
    }

    // Enter the bar. Pay some HONEYs. Earn some shares.
    // Locks Honey and mints xHoney
    function enter(uint256 _amount) public {
        // Gets the amount of Honey locked in the contract
        uint256 totalHoney = honey.balanceOf(address(this));
        // Gets the amount of xHoney in existence
        uint256 totalShares = totalSupply();
        // If no xHoney exists, mint it 1:1 to the amount put in
        if (totalShares == 0 || totalHoney == 0) {
            _mint(msg.sender, _amount);
        } 
        // Calculate and mint the amount of xHoney the Honey is worth. The ratio will change overtime, as xHoney is burned/minted and Honey deposited + gained from fees / withdrawn.
        else {
            uint256 what = _amount.mul(totalShares).div(totalHoney);
            _mint(msg.sender, what);
        }
        // Lock the Honey in the contract
        honey.transferFrom(msg.sender, address(this), _amount);
    }

    // Leave the bar. Claim back your HONEYs.
    // Unclocks the staked + gained Honey and burns xHoney
    function leave(uint256 _share) public {
        // Gets the amount of xHoney in existence
        uint256 totalShares = totalSupply();
        // Calculates the amount of Honey the xHoney is worth
        uint256 what = _share.mul(honey.balanceOf(address(this))).div(totalShares);
        _burn(msg.sender, _share);
        honey.transfer(msg.sender, what);
    }
}