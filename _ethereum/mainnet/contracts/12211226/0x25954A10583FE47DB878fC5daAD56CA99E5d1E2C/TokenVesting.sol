// SPDX-License-Identifier: MIT
pragma solidity ^0.6.8;

import "./SafeMath.sol";
import "./SafeERC20.sol";

contract TokenVesting {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event TokensReleased(address token, uint256 amount);

    address private _beneficiary;

    uint256 private _cliff;
    uint256 private _start;
    uint256 private _duration;

    mapping(address => uint256) private _released;

    constructor(
        address beneficiary,
        uint256 start,
        uint256 cliffDuration,
        uint256 duration
    ) public {
        require(beneficiary != address(0), 'TokenVesting: beneficiary is the zero address');
        require(cliffDuration <= duration, 'TokenVesting: cliff is longer than duration');
        require(duration > 0, 'TokenVesting: duration is 0');
        require(start.add(duration) > block.timestamp, 'TokenVesting: final time is before current time');

        _beneficiary = beneficiary;
        _duration = duration;
        _cliff = start.add(cliffDuration);
        _start = start;
    }

    function beneficiary() public view returns (address) {
        return _beneficiary;
    }

    function cliff() public view returns (uint256) {
        return _cliff;
    }

    function start() public view returns (uint256) {
        return _start;
    }

    function duration() public view returns (uint256) {
        return _duration;
    }

    function released(address token) public view returns (uint256) {
        return _released[token];
    }

    function releasable(IERC20 token) public view returns (uint256) {
        return _vestedAmount(token).sub(_released[address(token)]);
    }

    function release(IERC20 token) public {
        uint256 unreleased = releasable(token);

        require(unreleased > 0, 'TokenVesting: no tokens are due');

        _released[address(token)] = _released[address(token)].add(unreleased);

        token.safeTransfer(_beneficiary, unreleased);

        emit TokensReleased(address(token), unreleased);
    }

    function _vestedAmount(IERC20 token) private view returns (uint256) {
        uint256 currentBalance = token.balanceOf(address(this));
        uint256 totalBalance = currentBalance.add(_released[address(token)]);

        if (block.timestamp < _cliff) {
            return 0;
        } else if (block.timestamp >= _start.add(_duration)) {
            return totalBalance;
        } else {
            return totalBalance.mul(block.timestamp.sub(_start)).div(_duration);
        }
    }
}
