// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import "./ERC20.sol";

/**
 * @notice A mock version of wstETH token
 */
contract TestWstETH is ERC20 {
    IERC20 public stETH;

    constructor(IERC20 _stETH) ERC20("Test wstETH", "wstETH") {
        stETH = _stETH;
    }

    function wrap(uint256 _stETHAmount) external returns (uint256) {
        uint256 wstETHAmount;
        if (stETH.balanceOf(address(this)) > 0) {
            wstETHAmount =
                (totalSupply() * _stETHAmount) /
                stETH.balanceOf(address(this));
        } else {
            wstETHAmount = _stETHAmount;
        }
        stETH.transferFrom(msg.sender, address(this), _stETHAmount);
        _mint(msg.sender, wstETHAmount);
        return wstETHAmount;
    }

    function unwrap(uint256 _wstETHAmount) external returns (uint256) {
        uint256 stETHAmount = (stETH.balanceOf(address(this)) * _wstETHAmount) /
            totalSupply();
        _burn(msg.sender, _wstETHAmount);
        stETH.transfer(msg.sender, stETHAmount);
        return stETHAmount;
    }
}
