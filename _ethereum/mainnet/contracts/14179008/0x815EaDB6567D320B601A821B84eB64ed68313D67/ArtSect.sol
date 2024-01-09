// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20Upgradeable.sol";
import "./ERC20BurnableUpgradeable.sol";
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./UUPSUpgradeable.sol";

contract ArtSect is Initializable, ERC20Upgradeable, ERC20BurnableUpgradeable, OwnableUpgradeable, UUPSUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(address _tokenHolder) initializer public {
        __ERC20_init("ArtSect", "ART3");
        __ERC20Burnable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();

        _mint(_tokenHolder, 333000000 * 10 ** decimals());
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}
}
