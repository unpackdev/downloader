// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20Upgradeable.sol";
import "./ERC20BurnableUpgradeable.sol";
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./UUPSUpgradeable.sol";

contract MELD is
    Initializable,
    ERC20Upgradeable,
    OwnableUpgradeable,
    ERC20BurnableUpgradeable,
    UUPSUpgradeable
{
    function initialize() public initializer {
        __ERC20_init("MELD", "MELD");
        __ERC20Burnable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();

        mint(getMaxMints());
    }

    function getMaxMints() public view returns(uint256) {
        return 200000000 * 10 ** decimals();
    }

    function mint(uint256 amount) public onlyOwner {
        require(amount + totalSupply() <= getMaxMints(), 'Exceeds the maximum number of mintable');
        _mint(msg.sender, amount);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}
}