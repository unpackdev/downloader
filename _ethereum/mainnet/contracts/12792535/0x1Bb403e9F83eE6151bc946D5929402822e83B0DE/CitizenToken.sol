// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Roles.sol";
import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Pausable.sol";
import "./ERC20Votes.sol";
import "./AccessControlEnumerable.sol";
import "./Context.sol";

/**
 * @dev 
 **/
contract CitizenToken is Context, AccessControlEnumerable, ERC20Votes, ERC20Burnable, ERC20Pausable {

    bool public mintable;
    bool public pausable;

    constructor(
        string memory name,
        string memory symbol,
        address[] memory admins
    ) ERC20(name, symbol) ERC20Permit(name) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        for (uint i = 0; i < admins.length; i++) {
            _setupRole(DEFAULT_ADMIN_ROLE, admins[i]);
            _setupRole(Roles.PAUSER_ROLE, admins[i]);

            _mint(admins[i], 1 * 10**decimals());
        }
        mintable = true;
        pausable = true;
    }

    function mint(address to, uint256 amount) public {
        require(hasRole(Roles.MINTER_ROLE, _msgSender()), "CitizenToken: must have minter role to mint");
        require(mintable, "CitizenToken: No longer mintable");
        _mint(to, amount);
    }

    function revokeMinting() public {
        require(hasRole(Roles.REVOKER_ROLE, _msgSender()), "CitizenToken: must have minter role to end minting");
        require(mintable, "CitizenToken: minting already ended");
        mintable = false;
    }

    function pause() public virtual {
        require(hasRole(Roles.PAUSER_ROLE, _msgSender()), "CitizenToken: must have pauser role to pause");
        require(pausable, "CitizenToken: No longer pausable");
        _pause();
    }

    function revokePausing() public {
        require(hasRole(Roles.REVOKER_ROLE, _msgSender()), "CitizenToken: must have pauser role to end pausing");
        require(pausable, "CitizenToken: pausing already ended");
        pausable = false;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _mint(
        address account,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Votes) {
        super._mint(account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual override(ERC20, ERC20Votes) {
        super._burn(account, amount);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Votes) {
        super._afterTokenTransfer(from, to, amount);
    }
}
