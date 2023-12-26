// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IERC20.sol";
import "./ERC20.sol";
import "./SafeMath.sol";

contract veSAIL is ERC20("Vested SAIL", "veSAIL"){
    using SafeMath for uint256;
    IERC20 public sail;

    error VaultTokenNontransferable();

    uint256 EXCHANGE_RATE_PRECISION_MULT = 10**9;

    constructor(IERC20 _sail){
        sail = _sail;
    }

    function deposit(uint256 _amount) public {
        uint256 totalSail = sail.balanceOf(address(this));

        uint256 totalShares = totalSupply();

        if (totalShares == 0 || totalSail == 0) {
            _mint(msg.sender, _amount);
        } 
        else {
            uint256 what = _amount.mul(totalShares).div(totalSail);
            _mint(msg.sender, what);
        }

        sail.transferFrom(msg.sender, address(this), _amount);
    }

    function withdraw(uint256 _share) public {
        uint256 totalShares = totalSupply();
        uint256 what = _share.mul(sail.balanceOf(address(this))).div(totalShares);
        _burn(msg.sender, _share);
        sail.transfer(msg.sender, what);
    }

    function getExchangeRate() public view returns (uint256) {
        return (EXCHANGE_RATE_PRECISION_MULT*sail.balanceOf(address(this))) / totalSupply();
    }

    function toSAIL(uint256 veSAILAmount) public view returns (uint256 sailAmount) {
        sailAmount = (veSAILAmount * sail.balanceOf(address(this))) / totalSupply();
    }

    function toVESAIL(uint256 sailAmount) public view returns (uint256 veSailAmount) {
        veSailAmount = (sailAmount * totalSupply()) / sail.balanceOf(address(this));
    }

    /* Disable ERC20 Transfer and Approval functionality for vault shares */
    function _transfer(address from, address to, uint256 amount) internal override {
        revert VaultTokenNontransferable();
    }

    function _approve(address owner, address spender, uint256 amount) internal override {
        revert VaultTokenNontransferable();
    }
}
