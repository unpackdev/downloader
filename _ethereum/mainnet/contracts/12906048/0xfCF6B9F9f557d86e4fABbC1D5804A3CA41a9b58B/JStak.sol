// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Whitelist.sol";
import "./PausableUpgradeable.sol";
import "./ERC20VotesUpgradeable.sol";

contract Jstak is Whitelist, PausableUpgradeable, ERC20VotesUpgradeable {
    function __Jstak_init(string memory name, string memory symbol)
        public
        initializer
    {
        __Context_init_unchained();
        __ERC20_init_unchained(name, symbol);
        __EIP712_init_unchained(name, "1");
        __ERC20Permit_init_unchained();
        __ERC20Votes_init_unchained();
        __Jstak_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(JSTAK_ROLE, msg.sender);
    }

    function __Jstak_init_unchained() internal initializer {}

    /**
     * @dev Creates `amount` tokens to `account` by JSTAK role
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     */
    function mint(address to, uint256 amount) external returns (bool) {
        // Check that the calling account has the JSTAK_ROLE
        require(
            hasRole(JSTAK_ROLE, msg.sender),
            "JSTAK::CALLER_ISNT_JSTAK_ROLE"
        );
        _mint(to, amount);
        return true;
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     */
    function burn(address from, uint256 amount) public returns (bool) {
        // Check that the calling account has the JSTAK_ROLE
        require(
            hasRole(JSTAK_ROLE, msg.sender),
            "JSTAK::CALLER_ISNT_JSTAK_ROLE"
        );
        // Extra checks in case of non-owner implementation
        // uint256 currentAllowance = allowance(account, _msgSender());
        // require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        // unchecked {
        //     _approve(account, _msgSender(), currentAllowance - amount);
        // }
        _burn(from, amount);
        return true;
    }

    function pause() external whenNotPaused {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "JSTAK::CALLER_ISNT_ADMIN"
        );
        _pause();
    }

    function unpause() external whenPaused {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "JSTAK::CALLER_ISNT_ADMIN"
        );
        _unpause();
    }

    function grantJStakRole(address _address) external returns (bool) {
        require(
            hasRole(JSTAK_ROLE, msg.sender),
            "JSTAK::CALLER_ISNT_JSTAK_ROLE"
        );
        _grantRole(JSTAK_ROLE, _address);
        return true;
    }

    function revokeJStakRole(address _address) external returns (bool) {
        require(
            hasRole(JSTAK_ROLE, msg.sender),
            "JSTAK::CALLER_ISNT_JSTAK_ROLE"
        );
        _revokeRole(JSTAK_ROLE, _address);
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override whenNotPaused {
        require(isWhitelisted(recipient), "JSTAK::RECEIVER_NOT_WHITELISTED");
        super._transfer(sender, recipient, amount);
    }

    function getChainId() external view returns (uint256) {
        return block.chainid;
    }

    uint256[50] private __gap;
}
