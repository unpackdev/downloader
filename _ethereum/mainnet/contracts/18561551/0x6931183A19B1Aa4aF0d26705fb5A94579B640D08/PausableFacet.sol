// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./LibAppStorage.sol";
import "./LibPausable.sol";

contract PausableFacet is Modifiers {
    function pause() external onlyOwner {
        LibPausable._pause();
    }

    function unpause() external onlyOwner {
        LibPausable._unpause();
    }
}
