// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Balances.sol";
import "./CommonFunctions.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";


abstract contract ERC20Vesting is ERC20 {
    using Balances for Balances.Fungible;

    IERC20 immutable public token;
    uint64 immutable public vestingStart;
    uint64 immutable public vestingStop;
    uint64 immutable public cliff;

    Balances.Fungible private _released;

    constructor(IERC20 token_, uint64 vestingStart_, uint64 vestingStop_, uint64 cliff_) {
        token        = token_;
        vestingStart = vestingStart_;
        vestingStop  = vestingStop_;
        cliff        = cliff_;
    }

    function released(address user_) public view returns (uint256) {
        return _released.balanceOf(user_);
    }

    function totalReleased() public view returns (uint256) {
        return _released.totalSupply();
    }

    function vested(uint256 amount_, uint64 timestamp_) public view virtual returns (uint256) {
        return CommonFunctions.ramp(
            vestingStart,
            vestingStop,
            CommonFunctions.heaviside(cliff, amount_, timestamp_),
            timestamp_
        );
    }

    function releasable(address user_) public view virtual returns (uint256) {
        return vested(balanceOf(user_), uint64(block.timestamp)) - released(user_);
    }

    function release(address user_) public virtual returns (uint256) {
        uint256 toRelease = releasable(user_);

        _released.mint(user_, toRelease);
        SafeERC20.safeTransfer(token, user_, toRelease);

        return toRelease;
    }

    /// Disable transfer
    function _transfer(address, address, uint256) internal virtual override {
        revert('cannot transfer shares');
    }
}
