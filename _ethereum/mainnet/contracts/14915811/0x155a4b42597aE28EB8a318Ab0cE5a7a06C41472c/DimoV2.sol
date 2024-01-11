// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ERC20BurnableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./PausableUpgradeable.sol";

import "./UUPSUpgradeable.sol";

import "./CountersUpgradeable.sol";

import "./StorageV1.sol";

contract DimoV2 is
    ERC20BurnableUpgradeable,
    SnapshotStorageV1,
    AccessControlUpgradeable,
    PausableUpgradeable,
    EIP712StorageV1,
    ERC20PermitStorageV1,
    ERC20VotesStorageV1,
    UUPSUpgradeable
{
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override
        onlyRole(BURNER_ROLE)
    {
        super._burn(account, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {}
}
