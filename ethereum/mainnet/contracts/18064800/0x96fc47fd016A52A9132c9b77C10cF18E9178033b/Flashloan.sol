// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IFlashLoanSimpleReceiver.sol";
import "./IPool.sol";
import "./IERC20.sol";

contract Flashloan {
    IPool public pool;
    address public asset = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public owner;

    constructor (address _pool) {
        pool = IPool(_pool);
        owner = msg.sender;
    }

    function setAsset(address _contract) public { 
        asset = _contract;
    }

    // Receiver must approve the Pool contract for at least the amount borrowed + fee, else transaction will revert.
    function approvePool(uint256 _amount) public {
        IERC20(asset).approve(address(pool), _amount);
    }

    function flashloan(uint256 _amount) public { 
        pool.flashLoanSimple(address(this), asset, _amount, "", 0);
    }

    function deposit(uint256 _amount) public {
        IERC20(asset).transferFrom(msg.sender, address(this), _amount);
    }

    function withdraw(uint256 _amount) public {
        require(msg.sender == owner, "Must be owner to withdraw!");
        IERC20(asset).transfer(msg.sender, _amount);
    }

}

