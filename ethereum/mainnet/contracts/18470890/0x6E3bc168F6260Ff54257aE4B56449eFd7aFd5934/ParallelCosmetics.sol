pragma solidity 0.8.17;
// SPDX-License-Identifier: MIT

import "./ERC1155InvokeCutoff.sol";

contract ParallelCosmetics is ERC1155InvokeCutoff {
    constructor()
        ERC1155InvokeCutoff(
            true,
            "https://nftdata.parallelnft.com/api/parallel-cosmetics/ipfs/{id}",
            "Parallel Cosmetics",
            "LLCM"
        )
    {}
}
