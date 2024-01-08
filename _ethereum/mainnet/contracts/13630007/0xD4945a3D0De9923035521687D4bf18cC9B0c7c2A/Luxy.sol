// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20VotesUpgradeable.sol";
import "./Initializable.sol";

contract Luxy is Initializable, ERC20VotesUpgradeable {
    function __Luxy_init(string memory name, string memory symbol)
        external
        initializer
    {
        __Context_init_unchained();
        __ERC20_init_unchained(name, symbol);
        __EIP712_init_unchained(name, "1");
        __ERC20Permit_init_unchained(name);
        __ERC20Votes_init_unchained();
        __Luxy_init_unchained();
    }

    function __Luxy_init_unchained() internal initializer {
        _mint(_msgSender(), 1e26); /* 100M of tokens */
    }
}
