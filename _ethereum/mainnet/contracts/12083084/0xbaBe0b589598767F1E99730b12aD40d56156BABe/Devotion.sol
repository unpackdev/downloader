// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;

import "./ERC721Tradable.sol";

/**
 * @title DEVOTION
 * DEVOTION - the bridge between our worlds
 *
 * Read about the game at cryptobabes.org
 */
contract Devotion is ERC721Tradable {
    constructor(address _proxyRegistryAddress)
        ERC721Tradable(
            "DEVOTION Cryptobaebes Experience",
            "DEVOTION",
            _proxyRegistryAddress
        )
    {}

    function contractURI() public pure returns (string memory) {
        return
            "https://ipfs.io/ipfs/QmVGzMLoStEuQQXLaz8HVmgNiab18JDpvAKijgpgKnW4p5";
    }

    function baseTokenURI() public pure override returns (string memory) {
        return
            "https://ipfs.io/ipfs/QmNpWZKPsYb9EnbauP2iGVYsnPiXSwPfpsAJrz6UGMC1Bs/";
    }
}
