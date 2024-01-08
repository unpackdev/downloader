// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// ██╗      █████╗ ███╗   ███╗ ██████╗
// ██║     ██╔══██╗████╗ ████║██╔═══██╗
// ██║     ███████║██╔████╔██║██║   ██║
// ██║     ██╔══██║██║╚██╔╝██║██║   ██║
// ███████╗██║  ██║██║ ╚═╝ ██║╚██████╔╝
// ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝

import "./ExPopulusERC721WithSingleMetadataIPFS.sol";

contract LAMO_AFTRMATH_Ultra_001 is ExPopulusERC721WithSingleMetadataIPFS {
  constructor()
    ExPopulusERC721WithSingleMetadataIPFS(
        "AFTRMATH Ultra 001",
        "LAMO",
        "ipfs://",
        "QmQi3HkG7b1wNdDYP4uYuhc2MA3G6iDEYJgDh7L39sJ3g7",
        "https://ipfs.io/ipfs/",
        "QmYepg7schAmPktyvBmyi9ex7MkUdC2jr7FsyxXouK5bVX",
        33,
        330000000000000000,
        500,
        payable(address(0xbA1547331e29f1ee3606941B42A296f3a1612888)),
        payable(address(0xbA1547331e29f1ee3606941B42A296f3a1612888))
    ) {}
}
