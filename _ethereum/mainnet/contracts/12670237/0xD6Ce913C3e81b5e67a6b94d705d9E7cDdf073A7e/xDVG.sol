// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./IERC20.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";

// This contract handles swapping to and from xDVG, DAOventures's vip token
contract xDVG is ERC20("VIP DVG", "xDVG") {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public dvg;

    event Deposit(address indexed user, uint256 dvgAmount, uint256 xDVGAmount);
    event Withdraw(address indexed user, uint256 dvgAmount, uint256 xDVGAmount);

    // Define the DVG token contract
    constructor(IERC20 _dvg) public {
        dvg = _dvg;
    }

    // Pay some DVGs. Earn some shares. Locks DVG and mints xDVG
    function deposit(uint256 _amount) public {
        // Gets the amount of DVG locked in the contract
        uint256 totalDVG = dvg.balanceOf(address(this));
        // Gets the amount of xDVG in existence
        uint256 totalShares = totalSupply();
        uint256 what;
        // If no xDVG exists, mint it 1:1 to the amount put in
        if (totalShares == 0) {
            what = _amount;
            _mint(msg.sender, _amount);
        } 
        // Calculate and mint the amount of xDVG the DVG is worth. The ratio will change overtime
        else {
            what = _amount.mul(totalShares).div(totalDVG);
            _mint(msg.sender, what);
        }
        // Lock the DVG in the contract
        dvg.safeTransferFrom(msg.sender, address(this), _amount);

        emit Deposit(msg.sender, _amount, what);
    }

    // Claim back your DVGs. Unclocks the staked + gained DVG and burns xDVG
    function withdraw(uint256 _share) public {
        // Gets the amount of xDVG in existence
        uint256 totalShares = totalSupply();
        // Calculates the amount of DVG the xDVG is worth
        uint256 what = _share.mul(dvg.balanceOf(address(this))).div(totalShares);
        _burn(msg.sender, _share);
        dvg.safeTransfer(msg.sender, what);

        emit Withdraw(msg.sender, what, _share);
    }
}