// SPDX-License-Identifier: MIT
// Unagi Contracts v1.0.0 (MgcToken.sol)
pragma solidity 0.8.12;

import "./ERC777.sol";
import "./Multicall.sol";
import "./Pausable.sol";
import "./AccessControl.sol";

/**
 * @title MgcToken
 * @dev Implementation of IERC777. MGC token has an unlimited supply.
 * @custom:security-contact security@unagi.ch
 */
contract MgcToken is ERC777, Multicall, Pausable, AccessControl {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant PREDICATE_ROLE = keccak256("PREDICATE_ROLE");

    /**
     * @dev Create MGC contract.
     *
     * Setup predicate address as the predicate role.
     * See https://github.com/maticnetwork/matic-docs/blob/ae7315656703ed5d1394640e830ca6c8f591a7e4/docs/develop/ethereum-polygon/mintable-assets.md#contract-to-be-deployed-on-ethereum
     */
    constructor(address predicate)
        ERC777("Manager Contracts Token", "MGC", new address[](0))
    {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _setupRole(PREDICATE_ROLE, predicate);
    }

    /**
     * @dev Mint new tokens.
     *
     * Requirements:
     *
     * - Caller must have role PREDICATE_ROLE.
     * - The contract must not be paused.
     */
    function mint(address user, uint256 amount)
        external
        onlyRole(PREDICATE_ROLE)
        whenNotPaused
    {
        _mint(user, amount, "", "");
    }

    /**
     * @dev Pause token transfers.
     *
     * Requirements:
     *
     * - Caller must have role PAUSER_ROLE.
     */
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
     * @dev Unpause token transfers.
     *
     * Requirements:
     *
     * - Caller must have role PAUSER_ROLE.
     */
    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /**
     * @dev Before token transfer hook.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(operator, from, to, amount);
    }
}
