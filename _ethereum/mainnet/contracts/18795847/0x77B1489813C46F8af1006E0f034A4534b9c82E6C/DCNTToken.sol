// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./ERC20Permit.sol";
import "./ERC20Votes.sol";
import "./AccessControl.sol";
import "./IDCNTMintAuthorization.sol";

/// @notice the dcnt token
contract DCNTToken is ERC20, ERC20Permit, ERC20Votes, AccessControl {
    IDCNTMintAuthorization public mintAuthorization;
    bytes32 public constant MINT_ROLE = keccak256("MINT_ROLE");
    bytes32 public constant UPDATE_MINT_AUTHORIZATION_ROLE =
        keccak256("UPDATE_MINT_AUTHORIZATION_ROLE");
    error UnauthorizedMint();

    constructor(
        uint256 _supply,
        address _owner,
        IDCNTMintAuthorization _mintAuthorization,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) ERC20Permit(_name) {
        mintAuthorization = _mintAuthorization;
        _grantRole(DEFAULT_ADMIN_ROLE, _owner);
        _mint(msg.sender, _supply);
    }

    /// @notice public function to be used for minting new tokens
    /// @param dest address to assign newly minted tokens to
    /// @param amount amount of tokens to mint
    /// @dev only accounts with `MINT_ROLE` (the DAO) are authorized to mint more tokens
    function mint(address dest, uint256 amount) external onlyRole(MINT_ROLE) {
        if (!mintAuthorization.authorizeMint(dest, amount)) {
            revert UnauthorizedMint();
        }
        _mint(dest, amount);
    }

    /// @notice token burn function, with restrictions
    /// @dev only accounts with `MINT_ROLE` (the DAO) are authorized to burn their tokens
    function burn(uint256 amount) external onlyRole(MINT_ROLE) {
        _burn(msg.sender, amount);
    }

    /// @notice public function to update contract used for mint authorization
    /// @param newMintAuthorization address to use for the new mint authorization contract
    /// @dev only accounts with `UPDATE_MINT_AUTHORIZATION_ROLE` (the DAO) are authorized to update mint authorization
    function updateMintAuthorization(
        IDCNTMintAuthorization newMintAuthorization
    ) external onlyRole(UPDATE_MINT_AUTHORIZATION_ROLE) {
        mintAuthorization = newMintAuthorization;
    }

    // The following functions are overrides required by Solidity.

    function _update(
        address from,
        address to,
        uint256 value
    ) internal override(ERC20, ERC20Votes) {
        super._update(from, to, value);
    }

    function nonces(
        address owner
    ) public view override(ERC20Permit, Nonces) returns (uint256) {
        return super.nonces(owner);
    }
}
