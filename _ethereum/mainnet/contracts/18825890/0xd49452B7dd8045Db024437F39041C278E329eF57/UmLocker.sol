// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";

contract UmLocker is Ownable {
    using SafeERC20 for IERC20;

    event Released(uint256 amount);
    event Revoked();

    address public beneficiary;

    uint256 public cliff;
    uint256 public start;
    uint256 public duration;
    bool public revocable;

    mapping(address => uint256) public released;
    mapping(address => bool) public revoked;

    constructor(
        address _beneficiary,
        uint256 _start,
        uint256 _cliff,
        uint256 _duration,
        bool _revocable
    ) Ownable(_msgSender()) {
        require(_beneficiary != address(0));
        require(_cliff <= _duration);
        beneficiary = _beneficiary;
        revocable = _revocable;
        duration = _duration;
        cliff = _start + _cliff;
        start = _start;
    }

    function release(address _token) public {
        uint256 unreleased = releasableAmount(_token);
        require(unreleased > 0);
        released[_token] = released[_token] + unreleased;
        IERC20(_token).safeTransfer(beneficiary, unreleased);
        emit Released(unreleased);
    }

    function revoke(address _token) public onlyOwner {
        require(revocable);
        require(!revoked[_token]);
        uint256 balance = IERC20(_token).balanceOf(address(this));
        uint256 unreleased = releasableAmount(_token);
        uint256 refund = balance - unreleased;
        revoked[_token] = true;
        IERC20(_token).safeTransfer(owner(), refund);
        emit Revoked();
    }

    function closeRevocable() public onlyOwner {
        revocable = false;
    }

    function setBeneficiary(address beneficiary_) public onlyOwner {
        beneficiary = beneficiary_;
    }

    function releasableAmount(address _token) public view returns (uint256) {
        return vestedAmount(_token) - released[_token];
    }

    function vestedAmount(address _token) public view returns (uint256) {
        uint256 currentBalance = IERC20(_token).balanceOf(address(this));
        uint256 totalBalance = currentBalance + released[_token];
        if (block.timestamp < cliff) {
            return 0;
        } else if (block.timestamp >= start + duration || revoked[_token]) {
            return totalBalance;
        } else {
            return totalBalance * (block.timestamp - start) / duration;
        }
    }
}
