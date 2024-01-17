// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./Counters.sol";
import "./ERC721URIStorage.sol";
import "./ERC721Enumerable.sol";
import "./ERC721.sol";

contract NFT is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private nftTokenId;
    address contractAddress;

    constructor(address marketplaceAddress) ERC721("Unreal Kingdom", "UnKi") {
        contractAddress = marketplaceAddress;
    }

    function createNFtToken(string memory nftTokenURl) public returns (uint256) {
        nftTokenId.increment();
        uint256 id = nftTokenId.current();
        _mint(msg.sender, id);
        _setTokenURI(id, nftTokenURl);
        setApprovalForAll(contractAddress, true);
        return id;
    }
}
