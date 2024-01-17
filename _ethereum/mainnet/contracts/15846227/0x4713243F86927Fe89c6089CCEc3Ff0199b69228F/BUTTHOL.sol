// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: Butties Holiday Collection
// contract by: buildship.xyz

import "./ERC721Community.sol";

contract BUTTHOL is ERC721Community {
    constructor() ERC721Community("Butties Holiday Collection", "BUTTHOL", 5432, 500, START_FROM_ONE, "ipfs://bafybeid66h6fgdgl6uejjmsqpxcznpv2n3vbehw7gejphs5bur7kczfcdu/",
                                  MintConfig(0.0035 ether, 5, 15, 0, 0x0DB5Ca85E1e9AbF07FA9A80F1D1e14B761012252, false, false, false)) {}
}
