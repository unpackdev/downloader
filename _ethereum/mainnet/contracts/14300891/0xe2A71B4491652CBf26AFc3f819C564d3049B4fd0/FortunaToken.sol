// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./AccessControl.sol";
import "./draft-ERC20Permit.sol";
import "./ERC20Votes.sol";

contract FortunaToken is
    ERC20,
    ERC20Burnable,
    AccessControl,
    ERC20Permit,
    ERC20Votes
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor(address _multisig, address _fortunaGame)
        ERC20("Fortuna DAO", "FORTUNA")
        ERC20Permit("Fortuna DAO")
    {
        _grantRole(DEFAULT_ADMIN_ROLE, _multisig);
        _grantRole(MINTER_ROLE, _fortunaGame);
    }

    function mint(address _to, uint256 _amount) public onlyRole(MINTER_ROLE) {
        _mint(_to, _amount);
    }

    function addMinter(address _minter) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(MINTER_ROLE, _minter);
    }

    // The following functions are overrides required by Solidity.

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Votes) {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
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
