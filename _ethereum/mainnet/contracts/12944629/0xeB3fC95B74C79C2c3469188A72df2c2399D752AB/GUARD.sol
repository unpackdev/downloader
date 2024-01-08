// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./ERC721Tradable.sol";

contract Guardians is ERC721Tradable {
    constructor(
        address _proxyRegistryAddress
    ) ERC721Tradable('Guardians', 'GUARD', _proxyRegistryAddress) {}

    /**
     * @dev Link to Contract metadata https://docs.opensea.io/docs/contract-level-metadata
    */
    function contractURI() public pure returns (string memory) {
        return "https://arweave.net/dCrWzpeCgXkKcjvzFrGmiH3yNxMR0KwbfTccpXK6JXU";
    }
}
