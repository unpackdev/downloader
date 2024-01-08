pragma solidity ^0.5.0;

import "./ERC721Tradable.sol";
import "./Ownable.sol";

/**
 * @title Creature
 * Creature - a contract for my non-fungible creatures.
 */
contract MeoCards is ERC721Tradable {
    constructor(address _proxyRegistryAddress)
        public
        ERC721Tradable("MeoCards", "MEOCS", _proxyRegistryAddress)
    {}

    function baseTokenURI() public pure returns (string memory) {
        return "https://api.meocards.com/api/get-card/";
    }

    function contractURI() public pure returns (string memory) {
        return "https://meocards.com/contracts";
    }
}
