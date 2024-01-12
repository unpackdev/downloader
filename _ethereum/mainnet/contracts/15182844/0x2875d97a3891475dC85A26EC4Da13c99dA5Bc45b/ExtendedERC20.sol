// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "./GluwacoinModels.sol";
import "./draft-ERC20PermitUpgradeable.sol";

contract ExtendedERC20 is ContextUpgradeable, ERC20PermitUpgradeable {
    uint8 internal _decimals;

    mapping(address => mapping(GluwacoinModels.SigDomain => mapping(uint256 => bool))) internal _usedNonces;

    function __ExtendedERC20_init(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) internal onlyInitializing {
        __ExtendedERC20_init_unchained(name_, symbol_, decimals_);
    }

    function __ExtendedERC20_init_unchained(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) internal onlyInitializing {
        __ERC20_init(name_, symbol_);
        __ERC20Permit_init(name_);
        _decimals = decimals_;
    }

    function _useNonce(
        address signer,
        GluwacoinModels.SigDomain domain,
        uint256 nonce
    ) internal {
        require(!_usedNonces[signer][domain][nonce], 'ExtendedERC20: the nonce has already been used for this address');
        _usedNonces[signer][domain][nonce] = true;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function chainId() public view returns (uint256) {
        return block.chainid;
    }

    function _collect(
        address sender,
        uint256 amount,
        address collecter
    ) internal {
        if (amount > 0) {
            ERC20Upgradeable._transfer(sender, collecter, amount);
        }
    }

    uint256[50] private __gap;
}
