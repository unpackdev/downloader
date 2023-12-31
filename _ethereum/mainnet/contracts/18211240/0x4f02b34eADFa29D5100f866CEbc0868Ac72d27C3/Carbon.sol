// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "./UUPSUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";

import "./ERC20Upgradeable.sol";
import "./ERC20Minter.sol";
import "./IERC20Minter.sol";

contract Carbon is IERC20Minter, ERC20Minter, UUPSUpgradeable {
    function initialize(address dcarbon_) public initializer {
        __Ownable_init();
        initERC20Upgradeable("Carbon", "DC02");
        initERC20Minter(dcarbon_, 5e8);
    }

    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal virtual override onlyOwner {}
}
