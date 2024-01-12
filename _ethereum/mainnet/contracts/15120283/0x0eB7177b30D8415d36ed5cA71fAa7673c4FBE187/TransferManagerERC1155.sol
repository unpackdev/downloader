// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ITransferManager.sol";
import "./IERC1155Upgradeable.sol";

contract TransferManagerERC1155 is ITransferManager {
    address public immutable exchange;

    constructor(address _exchange) {
        exchange = _exchange;
    }

    function transferNFT(
        address collection,
        uint256 tokenId,
        uint256 amount,
        address from,
        address to
    ) external override {
        require(msg.sender == exchange, "TM1155: caller is not exchange");
        IERC1155Upgradeable(collection).safeTransferFrom(
            from,
            to,
            tokenId,
            amount,
            ""
        );
    }
}
