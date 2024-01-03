pragma solidity ^0.5.0;

import "./ERC721Tradable.sol";
import "./Ownable.sol";

/**
 * @title Creature
 * Creature - a contract for my non-fungible creatures.
 */
contract Tree is ERC721Tradable {
    constructor(address _proxyRegistryAddress)
        public
        ERC721Tradable("XmasTree", "CT20", _proxyRegistryAddress)
    {}

    function baseTokenURI() public pure returns (string memory) {
        return "https://xmas.cryptotree.art/api/token/";
    }

    function contractURI() public pure returns (string memory) {
        return "https://cryptotree.art/contract/";
    }
}
