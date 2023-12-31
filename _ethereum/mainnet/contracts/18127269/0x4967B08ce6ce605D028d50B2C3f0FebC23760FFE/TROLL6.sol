// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: Troll 6

import "./ERC721Community.sol";

contract TROLL6 is ERC721Community {
    constructor() ERC721Community("Troll 6", "TROLL6", 10000, 20, START_FROM_ONE, "ipfs://bafybeibj6x2qaw73utehtwcniyizcxiwvoxkppvdzoi5h4bq6vw2pnzk3a/",
                                  MintConfig(0.05 ether, 20, 20, 0, 0x7d678e09B8F3668fe89434623D5c71EbfF8A6DF5, true, false, false)) {}
}
