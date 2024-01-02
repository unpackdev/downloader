// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./UUPSUpgradeable.sol";
import "./ERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";

contract LiquidityWTF is UUPSUpgradeable, ERC20Upgradeable, OwnableUpgradeable {
    constructor() {
        _disableInitializers();
    }

    function initialize(uint256 _totalSupply) external initializer {
        __ERC20_init("liquiditydotwtf", "WTF");
        __Ownable_init();

        _mint(msg.sender, _totalSupply);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
