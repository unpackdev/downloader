// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./IERC721Receiver.sol";

contract BurnAddress is IERC721Receiver {
    
    function onERC721Received(address /*operator*/, address /*from*/, uint /*tokenId*/, bytes calldata /*data*/) 
        external virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
