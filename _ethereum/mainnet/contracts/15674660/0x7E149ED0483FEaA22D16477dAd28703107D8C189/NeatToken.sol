// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Context.sol";
import "./AccessControl.sol";
import "./ERC20Burnable.sol";
import "./ERC20Pausable.sol";
import "./ERC20Permit.sol";
import "./Initializable.sol";

/**
 * @title NeatToken
 * @author NeatFi
 * @notice Initiates the NeatFi token generation event (TGE) and mints Neat tokens.
 *         Minting only happens once, at the TGE. Afterwards, this contract is
 *         responsible for the Neat token transfer operations.
 */
contract NeatToken is
    Context,
    AccessControl,
    ERC20Burnable,
    ERC20Pausable,
    ERC20Permit,
    Initializable
{
    /**
     * @dev Only an address with a minter role will be able to mint Neat tokens
     *      at the TGE.
     */
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /**
     * @dev Pausers can pause all transfer operations on this contract.
     */
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /**
     * @notice Returns the hard-capped total supply of Neat tokens.
     */
    function totalSupply() public pure override returns (uint256) {
        return 2_000_000_000e18; // 2 Billion Neats
    }

    /**
     * @notice A public function to initiate the token generation event
     *         that mints all Neat tokens. This function can be invoked
     *         only once. There will be no way to mint more Neat tokens,
     *         ever. All the minted Neat tokens are transferred to the
     *         NeatFi DAO treasury to be distributed according to the
     *         tokenomics of the NeatFi protocol.
     * @dev Only available to a valid minter.
     * @param neatFiDaoTreasury - The address of the NeatFi DAO treasury.
     */
    function tokenGenerationEvent(address neatFiDaoTreasury)
        public
        whenNotPaused
        initializer
    {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "NeatToken::tokenGenerationEvent: caller is missing the MINTER_ROLE."
        );

        _beforeTokenTransfer(address(0), neatFiDaoTreasury, 2_000_000_000e18);

        _mint(neatFiDaoTreasury, 2_000_000_000e18);
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()));
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "NeatToken: must have pauser role to unpause"
        );
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }

    constructor(string memory _name, string memory _symbol)
        ERC20(_name, _symbol)
        ERC20Permit(_name)
    {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
    }
}
