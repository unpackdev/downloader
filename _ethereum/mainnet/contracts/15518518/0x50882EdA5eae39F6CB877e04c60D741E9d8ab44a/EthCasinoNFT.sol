/**
 *Submitted for verification at Etherscan.io on 2022-04-18
 */

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract EthCasinoNFT is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter public _tokenIds;

    constructor() ERC721('BNBPotRoulette', 'BNBPotRoulette') {}

    event Mint(uint256 tokenId);

    /**
     * @dev mint Casino NFTS
     *
     * @param tokenURI metadata url for NFT
     */
    function mint(string memory tokenURI) external onlyOwner {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();

        _mint(msg.sender, newItemId);
        _setTokenURI(newItemId, tokenURI);

        emit Mint(newItemId);
    }
}
