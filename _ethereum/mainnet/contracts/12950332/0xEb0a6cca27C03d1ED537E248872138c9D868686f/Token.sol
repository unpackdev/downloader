// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./ERC20Pausable.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract Authorizable is Ownable {
    mapping(address => bool) public authorized;

    modifier onlyAuthorized() {
        require(authorized[msg.sender] || owner() == msg.sender);
        _;
    }

    function addAuthorized(address _toAdd) public onlyOwner {
        authorized[_toAdd] = true;
    }

    function removeAuthorized(address _toRemove) public onlyOwner {
        require(_toRemove != msg.sender);
        authorized[_toRemove] = false;
    }
}

contract Token is
    ERC20("Instruaud", "IAUD"),
    Ownable,
    Authorizable,
    ERC20Burnable,
    ERC20Pausable
{
    uint256 private _cap = 5000000e18;

    function mint(address _to, uint256 _amount) public onlyAuthorized {
        _mint(_to, _amount);
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must be owner
     */
    function pause() public virtual onlyAuthorized {
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must be owner
     */
    function unpause() public virtual onlyAuthorized {
        _unpause();
    }

    /**
     * @dev Returns the cap on the token's total supply.
     */
    function cap() public view returns (uint256) {
        return _cap;
    }

    // Update the total cap - can go up or down but wont destroy prevoius tokens.
    function capUpdate(uint256 _newCap) public onlyAuthorized {
        _cap = _newCap;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);

        if (from == address(0)) {
            // When minting tokens
            require(
                totalSupply().add(amount) <= _cap,
                "ERC20Capped: cap exceeded"
            );
        }
    }
}
