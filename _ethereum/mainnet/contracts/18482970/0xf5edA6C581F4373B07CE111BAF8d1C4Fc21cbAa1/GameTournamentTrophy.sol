// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Pausable.sol";
import "./ERC20Capped.sol";
import "./AccessControlEnumerable.sol";


contract GameTournamentTrophy is
    ERC20,
    ERC20Burnable,
    ERC20Pausable,
    ERC20Capped,
    AccessControlEnumerable
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 cap_,
        address admin_
    ) ERC20(name_, symbol_) ERC20Capped(cap_) {
        require(admin_ != address(0), "GameTournamentTrophy: admin cannot be zero address");
        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
    }

    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    function _mint(address account, uint256 amount) internal override(ERC20, ERC20Capped) {
        super._mint(account, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }
}
