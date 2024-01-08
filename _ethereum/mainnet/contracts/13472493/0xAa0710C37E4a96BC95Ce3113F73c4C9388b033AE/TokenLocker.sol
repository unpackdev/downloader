// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./SafeERC20.sol";
import "./Context.sol";


abstract contract Ownable is Context {
    address private _owner;

    constructor() {
        _owner = _msgSender();
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _owner = newOwner;
    }
}

contract TokenLocker is Ownable {
    using SafeERC20 for IERC20;

    struct Lock {
        address beneficiary;
        uint256 releaseTime;
    }

    mapping(IERC20 => Lock) public locks;

    function lock(IERC20 token, uint256 numOfDays) external onlyOwner {
        require(numOfDays < 31, "duration is longer than 30 days");
        require(locks[token].releaseTime <= block.timestamp || token.balanceOf(address(this)) == 0, "token is locked");
        locks[token].beneficiary = owner();
        locks[token].releaseTime = block.timestamp + numOfDays * 1 days;
    }

    function release(IERC20 token) public virtual {
        require(block.timestamp >= locks[token].releaseTime, "current time is before release time");

        uint256 amount = token.balanceOf(address(this));
        require(amount > 0, "no tokens to release");

        token.safeTransfer(locks[token].beneficiary, amount);
        delete locks[token];
    }
}
