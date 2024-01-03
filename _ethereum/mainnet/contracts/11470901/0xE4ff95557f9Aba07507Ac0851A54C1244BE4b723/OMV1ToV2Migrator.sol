// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

contract OMV1ToV2Migrator {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 private _pool;
    IERC20 private _v1Token;
    IERC20 private _v2Token;

    function pool() public view returns (uint256) {
        return _pool;
    }

    function v1Token() public view returns (IERC20) {
        return _v1Token;
    }

    function v2Token() public view returns (IERC20) {
        return _v2Token;
    }

    constructor(IERC20 v1Token_, IERC20 v2Token_) public {
        _v1Token = v1Token_;
        _v2Token = v2Token_;
    }

    function increasePool(uint256 amount) external returns (bool success) {
        _v2Token.safeTransferFrom(msg.sender, address(this), amount);
        _pool = _pool.add(amount);
        return true;
    }

    function migrate(uint256 amount) external returns (bool success) {
        require(_pool >= amount, "Pool is extinguished");
        _pool = _pool.sub(amount);
        _v1Token.safeTransferFrom(msg.sender, address(this), amount);
        _v2Token.safeTransfer(msg.sender, amount);
        return true;
    }
}
