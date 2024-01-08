// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";

contract RoyalPausableUpgradeable is PausableUpgradeable, OwnableUpgradeable {

    function __RoyalPausableUpgradeable_init() internal initializer {
        __RoyalPausableUpgradeable_init_unchained();
    }

    function __RoyalPausableUpgradeable_init_unchained() internal initializer {
        __Pausable_init();
        __Ownable_init();
    }

    function pause() public virtual whenNotPaused onlyOwner {
        super._pause();
    }

    function unpause() public virtual whenPaused onlyOwner {
        super._unpause();
    }
}