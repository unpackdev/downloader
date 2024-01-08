// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IERC20.sol";
import "./ERC20.sol";
import "./SafeMath.sol";

//
// This contract handles swapping to and from PlatinumNugget, LuckySwap's staking token.
contract AlchemyBench is ERC20("AlchemyBench", "PLAN"){
    using SafeMath for uint256;
    IERC20 public goldnugget;

    // Define the GoldNugget token contract
    constructor(IERC20 _goldnugget) public {
        goldnugget = _goldnugget;
    }

    // Enter the alchemybench. Pay some GOLNs. Earn some shares.
    // Locks GoldNugget and mints PlatinumNugget
    function enter(uint256 _amount) public {
        // Gets the amount of GoldNugget locked in the contract
        uint256 totalGoldNugget = goldnugget.balanceOf(address(this));
        // Gets the amount of PlatinumNugget in existence
        uint256 totalShares = totalSupply();
        // If no PlatinumNugget exists, mint it 1:1 to the amount put in
        if (totalShares == 0 || totalGoldNugget == 0) {
            _mint(msg.sender, _amount);
        }
        // Calculate and mint the amount of PlatinumNugget the GoldNugget is worth. The ratio will change overtime, as PlatinumNugget is burned/minted and GoldNugget deposited + gained from fees / withdrawn.
        else {
            uint256 what = _amount.mul(totalShares).div(totalGoldNugget);
            _mint(msg.sender, what);
        }
        // Lock the GoldNugget in the contract
        goldnugget.transferFrom(msg.sender, address(this), _amount);
    }

    // Leave the alchemybench. Claim back your GOLNs.
    // Unlocks the staked + gained GoldNugget and burns PlatinumNugget
    function leave(uint256 _share) public {
        // Gets the amount of PlatinumNugget in existence
        uint256 totalShares = totalSupply();
        // Calculates the amount of GoldNugget the PlatinumNugget is worth
        uint256 what = _share.mul(goldnugget.balanceOf(address(this))).div(totalShares);
        _burn(msg.sender, _share);
        goldnugget.transfer(msg.sender, what);
    }
}
