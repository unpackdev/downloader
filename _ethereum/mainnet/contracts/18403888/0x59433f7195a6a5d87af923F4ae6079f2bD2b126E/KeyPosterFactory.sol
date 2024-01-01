// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.21;

import "./KeyPoster.sol";

contract KeyPosterFactory {
    event KeyPosterCreated(address indexed newKeyPoster, address indexed owner);

    function createKeyPoster() public returns (address) {
        KeyPoster newKeyPoster = new KeyPoster(msg.sender);
        emit KeyPosterCreated(address(newKeyPoster), msg.sender);
        return address(newKeyPoster);
    }
}
