// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Pausable.sol";
import "./AccessControl.sol";
import "./ERC20Capped.sol";
import "./VestingWallet.sol";

contract ArkeToken is
    ERC20,
    ERC20Burnable,
    Pausable,
    AccessControl,
    ERC20Capped,
    VestingWallet
{
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UNPAUSER_ROLE = keccak256("UNPAUSER_ROLE");
    uint32 public constant VESTING_START = 1641042000; //Vesting start : 01.01.2022
    uint32 public constant VESTING_TIME = 63072000; // 2 Years of vesting

    constructor(
        address owner,
        address pauser,
        address unpauser
    )
        ERC20("Arke Token", "ARKES")
        ERC20Capped(10000000 * 10**decimals())
        VestingWallet(owner, VESTING_START, VESTING_TIME)
    {
        _grantRole(DEFAULT_ADMIN_ROLE, owner);
        _grantRole(PAUSER_ROLE, pauser);
        _grantRole(UNPAUSER_ROLE, unpauser);
        //send initial supply (total supply is 10000000 divided between contract 80% and owner 20% )
        _mint(address(this), 8000000 * 10**decimals());
        _mint(owner, 2000000 * 10**decimals());
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(UNPAUSER_ROLE) {
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }

    // The following functions are overrides required by Solidity.

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20) {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20, ERC20Capped)
    {
        ERC20._mint(to, amount);
    }

    function _burn(address account, uint256 amount) internal override(ERC20) {
        super._burn(account, amount);
    }
}
