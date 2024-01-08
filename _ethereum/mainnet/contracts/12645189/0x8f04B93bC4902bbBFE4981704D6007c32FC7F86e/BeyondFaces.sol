// BeyondFaces.sol
// SPDX-License-Identifier: MIT

/* ]3 [- `/ () |\| |) /= /\ ( [- _\~
*
* An NFT project from JARI.
*  2021 BeyondFaces
*/

pragma solidity 0.8.4;

import "./ERC721Tradable.sol";

contract BeyondFaces is ERC721Tradable {
    constructor(address _proxyRegistryAddress)
    ERC721Tradable("BeyondFaces", "FACE", _proxyRegistryAddress){}

    function baseTokenURI() override public pure returns (string memory) {
        return "https://api.beyondfaces.io/face/";
    }

    function contractURI() public pure returns (string memory) {
        return "https://api.beyondfaces.io/contract";
    }
}
