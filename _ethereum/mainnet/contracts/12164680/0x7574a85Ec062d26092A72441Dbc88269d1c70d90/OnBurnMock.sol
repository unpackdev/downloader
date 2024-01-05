// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IOnBurn.sol";

contract OnBurnMock is IOnBurn {

    event MockBurnEvent(uint256 tokenId);

    function onBurn(uint256 tokenId) public override {
        emit MockBurnEvent(tokenId);
    }
}
