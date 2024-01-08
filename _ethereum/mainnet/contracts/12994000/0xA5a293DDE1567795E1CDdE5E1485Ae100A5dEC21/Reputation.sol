// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./ERC20Upgradeable.sol";
import "./ERC20BurnableUpgradeable.sol";
import "./OwnableUpgradeable.sol";

contract Reputation is
    Initializable,
    ERC20BurnableUpgradeable,
    OwnableUpgradeable
{
    mapping(address => bool) public whitelist;

    modifier onlyWhitelisted() {
        require(
            whitelist[_msgSender()] == true,
            "Reputation: caller is not a whitelisted address"
        );
        _;
    }

    function initialize(address[] memory tokenHolders, uint256[] memory amounts)
        public
        initializer
    {
        OwnableUpgradeable.__Ownable_init();
        ERC20BurnableUpgradeable.__ERC20Burnable_init();
        ERC20Upgradeable.__ERC20_init("dOrg", "dOrg");
        mintMultiple(tokenHolders, amounts);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        super._mint(to, amount);
    }

    function mintMultiple(
        address[] memory tokenHolders,
        uint256[] memory amounts
    ) public onlyOwner {
        require(
            tokenHolders.length == amounts.length,
            "Token holders and amounts lengths must match"
        );

        for (uint256 i = 0; i < tokenHolders.length; i++) {
            mint(tokenHolders[i], amounts[i]);
        }
    }

    function burnFrom(address account, uint256 amount)
        public
        override
        onlyOwner
    {
        super._burn(account, amount);
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        onlyWhitelisted
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function whitelistAdd(address _add) external onlyOwner {
        whitelist[_add] = true;
    }
}
