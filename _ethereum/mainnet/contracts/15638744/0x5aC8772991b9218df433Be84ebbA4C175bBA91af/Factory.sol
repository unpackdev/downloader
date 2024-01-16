//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AccessControl.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";

import "./IFactory.sol";


/**
 * Abstract base contract for factories.
 */
abstract contract Factory is
    IFactory,
    AccessControl,
    Pausable,
    ReentrancyGuard
{

    /*********/
    /* Types */
    /*********/

    /**
     * Constant used for representing the curator role.
     */
    bytes32 public constant CURATOR_ROLE = keccak256("CURATOR_ROLE");

    /**
     * Constant used for representing the minter role.
     */
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /*********/
    /* State */
    /*********/

    /**
     * Configurable marketplace address that will be granted the minter role in
     * created collections.
     */
    address private _marketplace;

    /***************/
    /* Constructor */
    /***************/

    /**
     * Creates a new instance of this contract.
     *
     * @param marketplace_ The configurable marketplace address that will be
     *     given minter role in created collections.
     */
    constructor(address marketplace_) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(MINTER_ROLE, CURATOR_ROLE);
        _marketplace = marketplace_;
    }

    /**********************/
    /* External functions */
    /**********************/

    /**
     * Sets the configurable marketplace address that will be given the minter
     * role in created collections.
     *
     * @param marketplace_ The marketplace address that will be given minter
     *     role in created collections.
     */
    function setMarketplace(address marketplace_)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _marketplace = marketplace_;
    }

    /********************/
    /* Public functions */
    /********************/

    /**
     * Returns the configured marketplace address that will be given the minter
     * role in created collections.
     *
     * @return The configured marketplace address that will be given minter
     *     role in created collections.
     */
    function marketplace() public view returns (address) {
        return _marketplace;
    }
}
