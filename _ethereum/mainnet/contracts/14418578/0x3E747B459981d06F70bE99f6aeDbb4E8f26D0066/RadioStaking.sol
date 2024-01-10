// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IERC20.sol";
import "./ERC20.sol";
import "./SafeMath.sol";

// This contract handles swapping to and from sRADIO, RadioShack Swap's staking token.
contract RadioStaking is ERC20("Staked RadioShack Token", "sRADIO"){
    using SafeMath for uint256;
    IERC20 public radio;

    // Define the Radio token contract
    constructor(IERC20 _radio) public {
        radio = _radio;
    }

    // Locks RADIO and mints sRADIO
    function enter(uint256 _amount) public {
        // Gets the amount of RADIO locked in the contract
        uint256 totalRadio = radio.balanceOf(address(this));
        // Gets the amount of sRADIO in existence
        uint256 totalShares = totalSupply();
        // If no sRADIO exists, mint it 1:1 to the amount put in
        if (totalShares == 0 || totalRadio == 0) {
            _mint(msg.sender, _amount);
        } 
        // Calculate and mint the amount of sRADIO the RADIO is worth. The ratio will change overtime, as sRADIO is burned/minted and Radio deposited + gained from fees / withdrawn.
        else {
            uint256 what = _amount.mul(totalShares).div(totalRadio);
            _mint(msg.sender, what);
        }
        // Lock the RADIO in the contract
        radio.transferFrom(msg.sender, address(this), _amount);
    }

    // Unlocks the staked + gained RADIO and burns sRADIO
    function leave(uint256 _share) public {
        // Gets the amount of sRADIO in existence
        uint256 totalShares = totalSupply();
        // Calculates the amount of RADIO the sRADIO is worth
        uint256 what = _share.mul(radio.balanceOf(address(this))).div(totalShares);
        _burn(msg.sender, _share);
        radio.transfer(msg.sender, what);
    }
}
