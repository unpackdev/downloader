// Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./ERC721URIStorage.sol";

contract PorqueTeAiloviu is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;

    constructor() ERC721("Porque Te Ailoviu", "NFT") {}

    function mintNFT(address recipient, string memory tokenURI, uint256 year)
        public onlyOwner
        returns (uint256)
    {
        _mint(recipient, year);
        _setTokenURI(year, tokenURI);

        return year;
    }
}
