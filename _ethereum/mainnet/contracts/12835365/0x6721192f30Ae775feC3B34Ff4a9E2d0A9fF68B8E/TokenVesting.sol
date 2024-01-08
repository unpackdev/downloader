// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract TokenVesting is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 constant MIN_PERIOD = 2629743;
    IERC20 private _punk =
        IERC20(address(0x558985b6eE1E4F5146060B1A2A56fd5c8FFb9C68));

    bool private _initialize = false;
    uint256 private _start;
    uint256 private _count;
    address private _beneficiary;

    uint256 private _released;

    constructor() Ownable() {
        transferOwnership(address(0xa8fd69E1f281E6b3548a3BE106f8B7D3a8bA41AB));
    }

    function writeCondition(address beneficiary, uint256 count) public onlyOwner {
        require(_initialize == false, "already initailized");
        require(beneficiary != address(0), "beneficiary is zero address");
        require(count > 0, "count is zero");

        _beneficiary = beneficiary;
        _start = _currentTimestamp();
        _count = count;
        _initialize = true;
    }

    function revoke() public onlyOwner {
        _punk.safeTransfer(owner(), _punk.balanceOf(address(this)));
    }

    function release() public {
        require(releasable() > 0, "releasable amount is zero");
        require(_start <= _currentTimestamp(), "too ealry");
        uint256 amount = releasable();
        _punk.safeTransfer(_beneficiary, amount);
        _released += amount;
    }

    function releasable() public view returns (uint256) {
        if (_start == 0) return 0;
        if (_punk.balanceOf(address(this)) == 0) return 0;

        uint256 count = _currentTimestamp().sub(_start).div(MIN_PERIOD);
        if (count > _count) count = _count;
        return _total().mul(count).div(_count).sub(_released);
    }

    function released() public view returns (uint256) {
        return _released;
    }

    function _currentTimestamp() private view returns (uint256) {
        return block.timestamp;
    }

    function _balanceOf() private view returns (uint256) {
        return _punk.balanceOf(address(this));
    }

    function _total() private view returns (uint256) {
        return released().add(_balanceOf());
    }

}
