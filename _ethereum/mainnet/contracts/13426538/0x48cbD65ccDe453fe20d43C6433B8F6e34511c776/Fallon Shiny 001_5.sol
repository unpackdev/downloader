// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// ██╗      █████╗ ███╗   ███╗ ██████╗
// ██║     ██╔══██╗████╗ ████║██╔═══██╗
// ██║     ███████║██╔████╔██║██║   ██║
// ██║     ██╔══██║██║╚██╔╝██║██║   ██║
// ███████╗██║  ██║██║ ╚═╝ ██║╚██████╔╝
// ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝

import "./ExPopulusERC721WithSingleMetadataIPFS.sol";

contract LAMO_Fallon_Shiny_001 is ExPopulusERC721WithSingleMetadataIPFS {
  constructor()
    ExPopulusERC721WithSingleMetadataIPFS(
        "Fallon Shiny 001",
        "LAMO",
        "ipfs://",
        "QmbZzSP8kW5DZiB6CSXJZf1tF6h1NKXP1YxaTsp12xHves",
        "https://ipfs.io/ipfs/",
        "QmVERMhrgnzT7EM1MhMRSdHidNMo7DGWGNHAPVSAFn7iNL",
        1,
        1,
        500,
        payable(address(0xbA1547331e29f1ee3606941B42A296f3a1612888)),
        payable(address(0xbA1547331e29f1ee3606941B42A296f3a1612888))
    ) {}
}
