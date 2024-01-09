// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./ERC20Upgradeable.sol";
import "./Initializable.sol";
import "./StringsUpgradeable.sol";

abstract contract BlocklistableUpgradable is Initializable, ContextUpgradeable {

    mapping(address => bool) internal blocklisted;

    event Blocklisted(address indexed _account);
    event UnBlocklisted(address indexed _account);

    function __Blocklistable_init() internal initializer {
        __Context_init_unchained();
        __Blocklistable_init_unchained();
    }

    function __Blocklistable_init_unchained() internal initializer {
    }

    function isBlocklisted(address account) public view virtual returns (bool) {
        return blocklisted[account];
    }

    modifier whenNotBlocklisted(address account) {
        require(
            !isBlocklisted(account),
            string(
                abi.encodePacked(
                    "Blocklistable: Address ",
                    StringsUpgradeable.toHexString(uint160(account), 20),
                    " is blocklisted"
                )
            )
        );
        _;
    }

    function _blocklist(address account) internal virtual {
        blocklisted[account] = true;
        emit Blocklisted(account);
    }

    function _unblocklist(address account) internal virtual {
        blocklisted[account] = false;
        emit UnBlocklisted(account);
    }

    uint256[49] private __gap;
}