// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./ERC20Snapshot.sol";
import "./AccessControl.sol";
import "./draft-ERC20Permit.sol";
import "./ERC20Votes.sol";

contract TickerDao is ERC20, ERC20Snapshot, AccessControl, ERC20Permit, ERC20Votes {
    bytes32 public constant SNAPSHOT_ROLE = keccak256("SNAPSHOT_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    
    bool canMint = true;

    constructor() ERC20("TickerDao", "TKR") ERC20Permit("TickerDao") {
        _setupRole(DEFAULT_ADMIN_ROLE, 0x3A7cbf0a90DC6755DdEE66886Dd26d4A6Ab64896);
        _setupRole(SNAPSHOT_ROLE, 0x3A7cbf0a90DC6755DdEE66886Dd26d4A6Ab64896);
        _mint(0x3A7cbf0a90DC6755DdEE66886Dd26d4A6Ab64896, 33333333 * 10 ** decimals());
        _setupRole(MINTER_ROLE, 0x3A7cbf0a90DC6755DdEE66886Dd26d4A6Ab64896);
    }

    function snapshot() public onlyRole(SNAPSHOT_ROLE) {
        _snapshot();
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
         _mint(to, amount);
    }
    
    function disableMint() public onlyRole(DEFAULT_ADMIN_ROLE) {
        canMint = false;
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
