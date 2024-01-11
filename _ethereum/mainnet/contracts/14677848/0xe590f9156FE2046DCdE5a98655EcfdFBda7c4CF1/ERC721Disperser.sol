// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2022 divergence.xyz
pragma solidity >=0.8.0 <0.9.0;

import "./IERC721.sol";

contract ERC721Disperser {
    struct TransferParamters {
        address receiver;
        uint96 tokenId;
    }

    function batchTransferTokens(
        IERC721 token,
        TransferParamters[] calldata params
    ) external {
        uint256 num = params.length;
        for (uint256 idx = 0; idx < num; ++idx) {
            token.transferFrom(
                msg.sender,
                params[idx].receiver,
                params[idx].tokenId
            );
        }
    }
}
