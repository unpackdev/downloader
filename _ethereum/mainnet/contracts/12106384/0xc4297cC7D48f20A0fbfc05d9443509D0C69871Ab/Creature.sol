pragma solidity ^0.5.0;

import "./ERC721Tradable.sol";
import "./Ownable.sol";

/**
 * @title Creature
 * We Are Masters.
 */
contract Creature is ERC721Tradable {
    constructor(address _proxyRegistryAddress)
        public
        ERC721Tradable("WeAreMasters", "WAM", _proxyRegistryAddress)
    {}

    function baseTokenURI() public pure returns (string memory) {
        return "https://wearemasters.io/api/assets/";
    }
}
