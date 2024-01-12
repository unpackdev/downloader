// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./ERC721C.sol";

contract Petabytes is ERC721C {
    constructor()
        ERC721C(
            "P1", // name
            "P1", // symbol
            2022, // collection size
            140000000000000000, // mint price public (0.14 ETH)
            0, // mint price allowlist (0.0 ETH)
            2, // max per wallet public
            1 // max per wallet allowlist
        )
    // solhint-disable-next-line no-empty-blocks
    {

    }
}
