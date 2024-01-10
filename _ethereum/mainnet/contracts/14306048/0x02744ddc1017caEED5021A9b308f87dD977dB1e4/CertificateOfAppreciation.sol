// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

import "./ERC721ProjectProxy.sol";

contract CertificateOfAppreciation is ERC721ProjectProxy {
    constructor()
        ERC721ProjectProxy(
            0x5D26CE1cB6F9fF7F07638cB3a170bc8a774b98DA,
            "David Ariew X Tatler China: Certificate of Appreciation",
            "CERT"
        )
    {}
}
