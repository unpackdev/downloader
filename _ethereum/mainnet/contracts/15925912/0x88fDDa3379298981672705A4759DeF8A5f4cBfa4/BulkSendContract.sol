// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./IERC721.sol";

contract BulkTransferer {
    IERC721 collection;

    constructor (address _collection) {
        collection = IERC721(_collection);
    }

    function bulkTransfer(address[] memory _to, uint256[] memory _tokenIds) external {
        require(_to.length == _tokenIds.length, "wrong params");
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            collection.transferFrom(msg.sender, _to[i], _tokenIds[i]);
        }
    }
}