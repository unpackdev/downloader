// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC1155Supply.sol";
import "./Ownable.sol";
import "./ECDSA.sol";
import "./IERC721.sol";

contract MultiSend {
    IERC721 vans;

    constructor(address a) {
        vans = IERC721(a);
    }

    function batchTransfer(address recipient, uint256[] calldata tokenIds) external {
        for (uint256 index; index < tokenIds.length; index++) {
            vans.safeTransferFrom(msg.sender, recipient, tokenIds[index]);
        }
    }
}