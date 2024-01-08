// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// ██╗      █████╗ ███╗   ███╗ ██████╗
// ██║     ██╔══██╗████╗ ████║██╔═══██╗
// ██║     ███████║██╔████╔██║██║   ██║
// ██║     ██╔══██║██║╚██╔╝██║██║   ██║
// ███████╗██║  ██║██║ ╚═╝ ██║╚██████╔╝
// ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝

import "./ExPopulusERC721WithSingleMetadataIPFS.sol";

contract LAMO_Fallon_Ultra_001 is ExPopulusERC721WithSingleMetadataIPFS {
  constructor()
    ExPopulusERC721WithSingleMetadataIPFS(
        "Fallon Ultra 001",
        "LAMO",
        "ipfs://",
        "Qma5BF2j86q8bkmxk5VHtDkMdGi9rdEhoqFNTzhfUMM9j4",
        "https://ipfs.io/ipfs/",
        "QmZJ4WBwtSxGdhpgyfNKXnUcPu8tSFdwYgwTZRs7N1H1SX",
        33,
        330000000000000000,
        500,
        payable(address(0xbA1547331e29f1ee3606941B42A296f3a1612888)),
        payable(address(0xbA1547331e29f1ee3606941B42A296f3a1612888))
    ) {}
}
