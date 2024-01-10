// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Snapshot.sol";
import "./AccessControl.sol";
import "./draft-ERC20Permit.sol";
import "./ERC20Votes.sol";

/// @custom:security-contact security@tkn.xyz
contract TokenDao is ERC20, ERC20Burnable, ERC20Snapshot, AccessControl, ERC20Permit, ERC20Votes {
    bytes32 public constant SNAPSHOT_ROLE = keccak256("SNAPSHOT_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor() ERC20("TokenDao", "TKN") ERC20Permit("TokenDao") {
        _grantRole(DEFAULT_ADMIN_ROLE, 0x3A7cbf0a90DC6755DdEE66886Dd26d4A6Ab64896);
        _grantRole(SNAPSHOT_ROLE, 0x3A7cbf0a90DC6755DdEE66886Dd26d4A6Ab64896);
        _mint(msg.sender, 33333333 * 10 ** decimals());
        _grantRole(MINTER_ROLE, 0x3A7cbf0a90DC6755DdEE66886Dd26d4A6Ab64896);
    }

    function snapshot() public onlyRole(SNAPSHOT_ROLE) {
        _snapshot();
    }

    function permanentlyDisableMint() public onlyRole(DEFAULT_ADMIN_ROLE) {
        canMint = false;
    }
    bool public canMint = true; // Can be permanently disabled above     

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    // The following functions are overrides required by Solidity.

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
        override(ERC20, ERC20Votes)
    {
        require(
            canMint == true,
            "Minting has been disabled"
        );
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._burn(account, amount);
    }
}
