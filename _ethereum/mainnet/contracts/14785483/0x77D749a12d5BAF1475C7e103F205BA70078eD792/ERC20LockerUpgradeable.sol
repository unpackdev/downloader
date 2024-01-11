// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "./IERC20StakingLocker.sol";
import "./IERC20Upgradeable.sol";
import "./LockerAdmin.sol";
import "./Errors.sol";

abstract contract ERC20LockerUpgradeable is LockerAdmin, IERC20StakingLocker {
    mapping(address => uint256) private _locked;
    IERC20Upgradeable private _parent;

    function __init() internal {
        _parent = IERC20Upgradeable(address(this));
    }

    function locked(address account) public view returns (uint256) {
        return _locked[account];
    }

    function lock(address account, uint256 amount) external {
        _onlyLockerAdmin();
        if (_parent.balanceOf(account) - _locked[account] < amount) revert InsufficientCAFE();
        _locked[account] += amount;
    }

    function unlock(address account, uint256 amount) external {
        _onlyLockerAdmin();
        if (_locked[account] < amount) revert AmountExceedsLocked();
        _locked[account] -= amount;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}
