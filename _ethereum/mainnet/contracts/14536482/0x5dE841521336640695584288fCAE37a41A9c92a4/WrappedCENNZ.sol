// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./ERC20.sol";
import "./ERC20Pausable.sol";
import "./AccessControl.sol";

contract WrappedCENNZ is ERC20, ERC20Pausable, AccessControl {
    /** @dev The minter role is the role that is allowed to mint/burn */
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor(address _pegAddress) ERC20("Wrapped CENNZ", "WCENNZ") {
        // Grant the peg address the role to mint
        _grantRole(MINTER_ROLE, _pegAddress);
        // Grant the contract deployer the default admin role: it will be able
        // to grant and revoke any roles
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /** @dev Upon token transfer, if the address is the minter role we burn the tokens.
      * @param owner The from address.
      * @param buyer The to address.
      * @param numTokens The number of tokens to be tranferred.
      * @return bool Whether the transfer was successful.
      */
    function transferFrom(address owner, address buyer, uint256 numTokens) public override returns (bool) {
        if (hasRole(MINTER_ROLE, msg.sender)) {
            burn(owner, numTokens);
            return true;
        }
        return super.transferFrom(owner, buyer, numTokens);
    }

    /** @dev Upon token transfer, if the address is the minter role we mint new tokens to the purchaser.
      * @param buyer The to address.
      * @param numTokens The number of tokens to be tranferred.
      * @return bool Whether the transfer was successful.
      */
    function transfer(address buyer, uint256 numTokens) public override returns (bool) {
        if (hasRole(MINTER_ROLE, msg.sender)) {
            mint(buyer, numTokens);
            return true;
        }
        return super.transfer(buyer, numTokens);
    }

    /** @dev The mint function is protected by the onlyRole modifier. */
    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    /** @dev The burn function is protected by the onlyRole modifier. */
    function burn(address from, uint256 amount) public onlyRole(MINTER_ROLE) {
        _burn(from, amount);
    }

    /** @dev The amount of decimals for Wrapped CENNZ is 4 decimals. */
    function decimals() public pure override returns (uint8) {
        return 4;
    }

    /** @dev Allow the admin to pause transfers. */
    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
      _pause();
    }

    /** @dev Allow the admin to unpause transfers. */
    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
      _unpause();
    }

    /** @dev Interfaces ERC20Pausable. */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }
}