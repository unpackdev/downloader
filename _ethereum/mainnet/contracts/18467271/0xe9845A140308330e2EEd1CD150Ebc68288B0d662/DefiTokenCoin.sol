// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Pausable.sol";
import "./Ownable.sol";
import "./ERC20Permit.sol";
import "./ERC20Votes.sol";

contract DefiTokenCoin is ERC20, ERC20Burnable, ERC20Pausable, Ownable, ERC20Permit, ERC20Votes {
    
    mapping(address => bool) public blacklists;
    mapping(address => bool) public lockuplists;
    
    constructor(address initialOwner)
        ERC20("Decentralized Finance Token", "DEFI")
        Ownable(initialOwner)
        ERC20Permit("Decentralized Finance Token")
    {
        _mint(initialOwner, 10000000 * 10 ** decimals());
    }

    function blacklist(
        address _address,
        bool _isBlacklisting
    ) external onlyOwner {
        blacklists[_address] = _isBlacklisting;
    }

    function lockup(
        address _address,
        bool _isLockingUp
    ) external onlyOwner {
        lockuplists[_address] = _isLockingUp;
    }


    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    // The following functions are overrides required by Solidity.

    function _update(address from, address to, uint256 value)
        internal
        override(ERC20, ERC20Pausable, ERC20Votes)
    {
        require(!blacklists[to] && !blacklists[from], "Blacklisted");
        require(!lockuplists[to] && !lockuplists[from], "Locked Up");
        super._update(from, to, value);

    }

    function nonces(address owner)
        public
        view
        override(ERC20Permit, Nonces)
        returns (uint256)
    {
        return super.nonces(owner);
    }
}
