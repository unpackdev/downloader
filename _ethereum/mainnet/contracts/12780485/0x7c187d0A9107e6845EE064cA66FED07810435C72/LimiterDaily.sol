// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ILimiter.sol";

contract LimiterDaily is ILimiter, Ownable {
    // IBridge address => timestamp (day) => usage
    mapping (address => mapping (uint256 => uint256)) private _usages;
    mapping (address => uint256) private _limiter;

    uint256 constant private TIME_BLOCK = 86400;

    // limit = 0 is unlimited
    function setLimit(address bridge, uint256 limit) external onlyOwner {
        _limiter[bridge] = limit;
    }

    function getLimit(address bridge) override public view returns (uint256) {
        return _limiter[bridge];
    }

    function getUsage(address bridge) override public view returns (uint256) {
        uint256 ts = block.timestamp / TIME_BLOCK;
        uint256 usage = _usages[bridge][ts];
        return usage;
    }

    function isLimited(address bridge, uint256 amount) override public view returns (bool) {
        if (_limiter[bridge] == 0) {
            return false;
        }

        return getUsage(bridge) + amount > getLimit(bridge);
    }

    function increaseUsage(uint256 amount) override external {
        address bridge = _msgSender();

        // this prevent unknown contract to change usage value
        if (_limiter[bridge] == 0) {
            return;
        }

        uint256 ts = block.timestamp / TIME_BLOCK;
        _usages[bridge][ts] += amount;
        require(_usages[bridge][ts] <= _limiter[bridge], "LimiterDaily: limit exceeded");
    }
}
