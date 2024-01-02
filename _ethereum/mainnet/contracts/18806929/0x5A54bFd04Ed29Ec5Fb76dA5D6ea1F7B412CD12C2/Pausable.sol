// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "./IPausable.sol";
import "./PausableInternal.sol";

/**
 * @title Pausable security control module.
 */
abstract contract Pausable is IPausable, PausableInternal {
    /**
     * @inheritdoc IPausable
     */
    function paused() external view virtual returns (bool status) {
        status = _paused();
    }
}
