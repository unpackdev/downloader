// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "./ERC20Burnable.sol";
import "./ERC20Votes.sol";
import "./Pausable.sol";
import "./AccessControl.sol";

contract YooldoToken is ERC20Burnable, ERC20Votes, AccessControl, Pausable {
    uint256 public constant MAXIMUM_SUPPLY = 1000000000 * 10**18; // 1 billion
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor(address owner) ERC20("YooldoToken", "YOOL") ERC20Permit("YooldoToken") {
        _grantRole(DEFAULT_ADMIN_ROLE, owner);
        _grantRole(PAUSER_ROLE, owner);
        _grantRole(MINTER_ROLE, owner);
        _mint(owner, MAXIMUM_SUPPLY);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override(ERC20) whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _afterTokenTransfer (address from, address to, uint256 amount) internal override(ERC20, ERC20Votes) {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount) internal override(ERC20, ERC20Votes) {
        require(totalSupply() + amount <= MAXIMUM_SUPPLY, "YooldoToken: total supply exceeds maximum supply");
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount) internal override(ERC20, ERC20Votes) {
        super._burn(account, amount);
    }
}