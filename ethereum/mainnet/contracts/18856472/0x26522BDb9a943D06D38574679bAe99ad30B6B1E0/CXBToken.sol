// SPDX-License-Identifier: Private
pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Pausable.sol";
import "./AccessManaged.sol";
import "./ERC20Permit.sol";
import "./Freezable.sol";

contract CXBToken is
    ERC20,
    ERC20Burnable,
    ERC20Pausable,
    AccessManaged,
    ERC20Permit,
    Freezable
{
    /**
     * @dev Indicates an error when freezed address called function
     * @param account Address who calls
     */
    error CXBTokenAddressFreezed(address account);

    constructor(
        address initialAuthority,
        uint256 premintAmount
    )
        ERC20("CXBToken", "CXBT")
        AccessManaged(initialAuthority)
        ERC20Permit("CXBToken")
    {
        _mint(initialAuthority, premintAmount * 10 ** decimals());
    }

    function pause() public restricted {
        _pause();
    }

    function unpause() public restricted {
        _unpause();
    }

    function freeze(address target) public restricted {
        _freeze(target);
    }

    function unfreeze(address target) public restricted {
        _unfreeze(target);
    }

    function mint(
        address to,
        uint256 amount
    ) public restricted whenNotFreezed(to) {
        _mint(to, amount);
    }

    // The following functions are overrides required by Solidity.

    function _update(
        address from,
        address to,
        uint256 value
    )
        internal
        override(ERC20, ERC20Pausable)
        whenNotPaused
        whenNotFreezed(to)
        whenNotFreezed(from)
    {
        super._update(from, to, value);
    }

    function transfer(
        address to,
        uint256 value
    )
        public
        virtual
        override
        whenNotPaused
        whenNotFreezed(to)
        whenNotFreezed(msg.sender)
        returns (bool)
    {
        address owner = _msgSender();
        _transfer(owner, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    )
        public
        virtual
        override
        whenNotPaused
        whenNotFreezed(to)
        whenNotFreezed(from)
        returns (bool)
    {
        address spender = _msgSender();
        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
        return true;
    }
}
