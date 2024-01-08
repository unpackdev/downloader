//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./ERC721URIStorage.sol";
import "./Ownable.sol";

contract HonoraryHappyBunnies is ERC721URIStorage, Ownable {
    constructor() ERC721("Honorary Happy Bunnies", "HHB") {}

    uint256 private nextId;

    function mintHonorary(address honorable, string memory ipfsUri)
        external
        onlyOwner
    {
        nextId++;
        _mint(honorable, nextId);
        _setTokenURI(nextId, ipfsUri);
    }

    function changeTokenURI(uint256 tokenId, string memory ipfsUri)
        external
        onlyOwner
    {
        _setTokenURI(tokenId, ipfsUri);
    }
}
