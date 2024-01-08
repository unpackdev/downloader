// contracts/MyNFT.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721PresetMinterPauserAutoId.sol";

contract RadixNft is ERC721PresetMinterPauserAutoId {

    constructor()
        ERC721PresetMinterPauserAutoId(
            "Radix Nft",
            "RDX",
            "https://gateway.pinata.cloud/ipns/k2k4r8mpdju5927qlhmfe0dekwjxgn5jhlintmnftlytt2hui8xv1vhs/"
        )
    {}

}
