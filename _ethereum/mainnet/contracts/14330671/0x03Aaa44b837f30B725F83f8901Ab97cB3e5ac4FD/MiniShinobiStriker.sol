// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";
import "./base64.sol";


/**
 * @title Mini Shinobi Strikers
 * Mini Shinobi Strikers - a contract for Mini Shinobi Strikers.
 */
contract MiniShinobiStriker is ERC721Tradable {
    string _contractURI;

    constructor(address _proxyRegistryAddress)
        ERC721Tradable("Mini Shinobi Striker", "MSS", _proxyRegistryAddress)
    {}

    function baseTokenURI() override public pure returns (string memory) {
        return "https://gateway.pinata.cloud/ipfs/QmeHyw7xif6xnKYXjgUQpP2GtHVs8d6qhEbp6gR4Nx3VdF/";
    }

    function contractURI() public pure returns (string memory) {
        return "https://gateway.pinata.cloud/ipfs/QmPh5dt5ppLLuz5T8rXHh7LqgiiWnm94cm1mD4y2Pc1rf4";
    }

}
