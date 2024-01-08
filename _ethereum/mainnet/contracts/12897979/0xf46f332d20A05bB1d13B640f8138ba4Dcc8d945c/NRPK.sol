// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./ERC721Tradable.sol";

contract NRPK is ERC721Tradable {
    constructor(
        address _proxyRegistryAddress
    ) ERC721Tradable('NeuraPunks', 'NRPK', _proxyRegistryAddress) {}

    /**
     * @dev Link to Contract metadata https://docs.opensea.io/docs/contract-level-metadata
    */
    function contractURI() public pure returns (string memory) {
        return "https://arweave.net/R7LBo6D31Ef9BWejtR4XvRx29TmpreBjHX4EQvgVioQ";
    }
}
