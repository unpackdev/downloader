// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "./IERC1155Upgradeable.sol";
import "./IERC1155StakingLocker.sol";
import "./LockerAdmin.sol";
import "./Errors.sol";

abstract contract ERC1155LockerUpgradeable is
    LockerAdmin,
    IERC1155StakingLocker
{
    mapping(address => mapping(uint256 => uint256)) private _locked;
    IERC1155Upgradeable private _parent;

    function __init() internal {
        _parent = IERC1155Upgradeable(address(this));
    }

    function lock(
        address account,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external {
        _onlyLockerAdmin();

        if (ids.length != amounts.length) revert InvalidArrayLength();

        mapping(uint256 => uint256) storage accountLocked = _locked[account];

        for (uint256 t = 0; t < ids.length; t++) {
            uint256 tokenId = ids[t];
            uint256 tokenAmount = amounts[t];
            if (
                _parent.balanceOf(account, tokenId) - accountLocked[tokenId] <
                tokenAmount
            ) revert InsufficientBalance();
            accountLocked[tokenId] += tokenAmount;
        }
    }

    function unlock(
        address account,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external {
        _onlyLockerAdmin();
        
        if (ids.length != amounts.length) revert InvalidArrayLength();

        mapping(uint256 => uint256) storage accountLocked = _locked[account];

        for (uint256 t = 0; t < ids.length; t++) {
            if (accountLocked[ids[t]] < amounts[t])
                revert InsufficientBalance();
            accountLocked[ids[t]] -= amounts[t];
        }
    }

    function locked(address account, uint256 id) public view returns (uint256) {
        return _locked[account][id];
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}
