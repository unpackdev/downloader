// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ITransferManager.sol";
import "./IERC721Upgradeable.sol";

contract TransferManagerERC721 is ITransferManager {
    address public immutable exchange;

    constructor(address _exchange) {
        exchange = _exchange;
    }

    function transferNFT(
        address collection,
        uint256 tokenId,
        uint256, /* amount */
        address from,
        address to
    ) external override {
        require(msg.sender == exchange, "TM721: caller is not exchange");
        IERC721Upgradeable(collection).safeTransferFrom(from, to, tokenId);
    }
}
