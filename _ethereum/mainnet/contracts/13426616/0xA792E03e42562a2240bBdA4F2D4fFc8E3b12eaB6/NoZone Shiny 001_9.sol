// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// ██╗      █████╗ ███╗   ███╗ ██████╗
// ██║     ██╔══██╗████╗ ████║██╔═══██╗
// ██║     ███████║██╔████╔██║██║   ██║
// ██║     ██╔══██║██║╚██╔╝██║██║   ██║
// ███████╗██║  ██║██║ ╚═╝ ██║╚██████╔╝
// ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝

import "./ExPopulusERC721WithSingleMetadataIPFS.sol";

contract LAMO_NoZone_Shiny_001 is ExPopulusERC721WithSingleMetadataIPFS {
  constructor()
    ExPopulusERC721WithSingleMetadataIPFS(
        "NoZone Shiny 001",
        "LAMO",
        "ipfs://",
        "QmfVUT5HaSpAHXhuvSRpH6SwXmNJz2JdB59ChebeUNrfNB",
        "https://ipfs.io/ipfs/",
        "QmY2CGAPGEs9yyGDSFRBcWoaXQAQEvgYr3DgiJgkwCANa6",
        1,
        1,
        500,
        payable(address(0xbA1547331e29f1ee3606941B42A296f3a1612888)),
        payable(address(0xbA1547331e29f1ee3606941B42A296f3a1612888))
    ) {}
}
