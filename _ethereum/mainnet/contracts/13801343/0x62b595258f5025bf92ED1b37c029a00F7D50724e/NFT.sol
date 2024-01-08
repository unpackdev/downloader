
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./ERC721URIStorage.sol";

contract NFT is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    address contractAddress;

    constructor(address marketplaceAddress) ERC721("TESTN", "TST") {
        contractAddress = marketplaceAddress;
    }
    event Burned(uint256 nftID);


    function mintNFT(string memory tokenURI)
        public
        returns (uint256)
    {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();

        _mint(msg.sender, newItemId);
        _setTokenURI(newItemId, tokenURI);
        setApprovalForAll(contractAddress, true);
        return newItemId;
    }
    //burn nft
    function removeNFT(uint256 _tokenId) public {
        require(ownerOf(_tokenId) == msg.sender);
            
        _burn(_tokenId);
        emit Burned(_tokenId);

  }

   function _mintBatch(
        string[] memory tokenURI,
        uint256[] memory quantity
    ) public {

        for (uint256 i = 0; i < tokenURI.length; i++) {
            for (uint256 j = 0; j < quantity[i]; j++) {
                _tokenIds.increment();
                uint256 newItemId = _tokenIds.current();
                _mint(msg.sender, newItemId);
                _setTokenURI(newItemId, tokenURI[i]);
                setApprovalForAll(contractAddress, true);
            }
        }

    }
}
