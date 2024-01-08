// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";

/**
 * @title Creature
 * Creature - a contract for my non-fungible creatures.
 */
contract HallOfFame is ERC721Tradable {
    string baseURI = "https://p.noncebox.com/api/info/";

    constructor(address _proxyRegistryAddress)
        ERC721Tradable(
            "Hall of Fame",
            "HoF",
            151,
            800,
            7000,
            50,
            1,
            1,
            10,
            _proxyRegistryAddress
        )
    {}

    function setBaseTokenURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
        emit BaseTokenURIChanged(baseURI);
    }

    function baseTokenURI() public view override returns (string memory) {
        return baseURI;
    }
}
