pragma solidity ^0.5.0;

import "./ERC721Tradable.sol";
import "./Ownable.sol";

/**
 * @title Creature
 * Creature - a contract for my non-fungible creatures.
 */
contract FuturamaCryptoCans is ERC721Tradable {
    constructor(address _proxyRegistryAddress)
        public
        ERC721Tradable("FuturamaCryptoCans", "FCT", _proxyRegistryAddress)
    {}

    function baseTokenURI() public pure returns (string memory) {
        return "https://api.futurama.ai/creature/";
    }

    function contractURI() public pure returns (string memory) {
        return "https://api.futurama.ai/contract";
    }
}
