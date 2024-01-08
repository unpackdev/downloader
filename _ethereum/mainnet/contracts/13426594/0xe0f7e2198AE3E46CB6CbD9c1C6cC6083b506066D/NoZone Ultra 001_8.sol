// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// ██╗      █████╗ ███╗   ███╗ ██████╗
// ██║     ██╔══██╗████╗ ████║██╔═══██╗
// ██║     ███████║██╔████╔██║██║   ██║
// ██║     ██╔══██║██║╚██╔╝██║██║   ██║
// ███████╗██║  ██║██║ ╚═╝ ██║╚██████╔╝
// ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝

import "./ExPopulusERC721WithSingleMetadataIPFS.sol";

contract LAMO_NoZone_Ultra_001 is ExPopulusERC721WithSingleMetadataIPFS {
  constructor()
    ExPopulusERC721WithSingleMetadataIPFS(
        "NoZone Ultra 001",
        "LAMO",
        "ipfs://",
        "QmWpcj1M2mHYZergyhtCWPtq3BzQmZUz4WW3fPEGtWd7fE",
        "https://ipfs.io/ipfs/",
        "QmQYz6ctFNFDUN8RX7vNcft8dwbPURe2tvLm6nDCReyuQv",
        33,
        330000000000000000,
        500,
        payable(address(0xbA1547331e29f1ee3606941B42A296f3a1612888)),
        payable(address(0xbA1547331e29f1ee3606941B42A296f3a1612888))
    ) {}
}
