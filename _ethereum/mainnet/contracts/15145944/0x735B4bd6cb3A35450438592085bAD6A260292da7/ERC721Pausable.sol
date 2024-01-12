// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./Pausable.sol";
import "./ERC721.sol";

abstract contract ERC721Pausable is ERC721, Pausable {

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}
