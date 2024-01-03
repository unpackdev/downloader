// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./IERC20.sol";
import "./ERC20.sol";
import "./SafeMath.sol";
import "./CarveToken.sol";

// This contract handles swapping to and from sCARVE, CARVE's staking token.
contract CarveStaking is ERC20("Staked CARVE", "sCARVE") {
    using SafeMath for uint256;
    CarveToken public carve;

    constructor(address carve_) {
        carve = CarveToken(carve_);
    }

    // Price of 1 sCARVE over CARVE (should increase gradiently over time)
    function getPricePerFullShare() external view returns (uint256) {
        uint256 totalShares = totalSupply();
        return (totalShares == 0) ? 1e18 : carve.balanceOf(address(this)).div(totalShares);
    }

    // Locks CARVE and mints sCARVE
    function stake(uint256 amount) public {
        // The real amount being staked
        uint256 amountMinusFee = amount.sub(carve.feeForAmount(amount));
        // Gets the amount of Carve locked in the contract
        uint256 totalCarve = carve.balanceOf(address(this));
        // Gets the amount of sCARVE in existence
        uint256 totalShares = totalSupply();
        // If no sCARVE exists, mint it 1:1 to the amount put in
        if (totalShares == 0 || totalCarve == 0) {
            _mint(msg.sender, amountMinusFee);
        }
        // Calculate and mint the amount of sCARVE the Carve is worth.
        // The ratio will change overtime, as sCARVE is burned/minted and Carve deposited + gained from fees / withdrawn.
        else {
            uint256 sCARVE = amountMinusFee.mul(totalShares).div(totalCarve);
            _mint(msg.sender, sCARVE);
        }
        // Lock the Carve in the contract
        carve.transferFrom(msg.sender, address(this), amount);
    }

    // Claim back your CARVE.
    // Unlocks the staked + gained Carve and burns sCARVE
    function unstake(uint256 share) public {
        // Gets the amount of sCARVE in existence
        uint256 totalShares = totalSupply();
        // Calculates the amount of Carve the sCARVE is worth
        uint256 carveAmount = share.mul(carve.balanceOf(address(this))).div(totalShares);
        _burn(msg.sender, share);
        carve.transfer(msg.sender, carveAmount);
    }

    // Burn all sCARVE you have and get back CARVE.
    function exit() public {
        unstake(balanceOf(msg.sender));
    }
}