// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IOnMint.sol";

contract OnMintMock is IOnMint {

    event MockMintEvent(address minter, address to, uint256 tokenId, uint256 extra);

    function onMint(address minter, address to, uint256 tokenId, uint256 extra) public override {
        emit MockMintEvent(minter, to, tokenId, extra);
    }
}
