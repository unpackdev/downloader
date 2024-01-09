// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20Capped.sol";
import "./ERC20Burnable.sol";
import "./ERC20Snapshot.sol";
import "./Ownable.sol";
import "./draft-ERC20Permit.sol";
import "./ERC20Votes.sol";

contract PaycerToken is ERC20Capped, ERC20Burnable, ERC20Snapshot, Ownable, ERC20Permit, ERC20Votes { 
    constructor(uint256 _totalSupply) 
        ERC20("Paycer", "PCR") 
        ERC20Permit("Paycer") 
        ERC20Capped(_totalSupply)
    {

    }

    function snapshot() public onlyOwner {
        _snapshot();
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function getChainId() external view returns (uint256) {
        uint256 chainId;
        
        assembly {
            chainId := chainid()
        }

        return chainId;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Snapshot)
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20, ERC20Capped, ERC20Votes)
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._burn(account, amount);
    }
}