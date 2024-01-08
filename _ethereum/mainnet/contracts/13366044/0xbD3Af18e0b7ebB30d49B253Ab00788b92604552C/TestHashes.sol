// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Hashes.sol";

contract TestHashes is Hashes(1000000000000000000, 100, 1000, "https://example.com/") {
    function setNonce(uint256 _nonce) public nonReentrant {
        nonce = _nonce;
    }
}
