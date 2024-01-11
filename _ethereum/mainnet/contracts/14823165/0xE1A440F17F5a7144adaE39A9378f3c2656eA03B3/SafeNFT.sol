pragma solidity ^0.8.4;
//SPDX-License-Identifier: UNLICENSED

import "./ERC721A.sol";

struct NFT {
    address contractAddress;
    uint256 tokenId;
    address owner;
}

contract REPL is ERC721A {
    mapping(uint256 => NFT) nfts;
    address owner;
    bool paused = false;

    constructor() ERC721A("Replicas NFT", "REPL") {
        owner = msg.sender;
    }

    function flipPaused() external {
        assert(msg.sender == owner);
        paused = !paused;
    }

    function mint(address contractAddress, uint256 tokenId) external payable {
        assert(msg.sender.code.length == 0 && !paused);
        OriginalNFT originalNFT = OriginalNFT(contractAddress);
        assert(originalNFT.ownerOf(tokenId) == msg.sender);

        NFT memory nft = NFT(contractAddress, tokenId, msg.sender);
        nfts[_currentIndex] = nft;
        _safeMint(msg.sender, 1);
    }

    function mintFor(address _owner, address contractAddress, uint256 tokenId) external payable {
        require(msg.sender == owner);
        NFT memory nft = NFT(contractAddress, tokenId, _owner);
        nfts[_currentIndex] = nft;
        _safeMint(msg.sender, 1);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        assert(!paused && tokenId < _currentIndex);
        OriginalNFT originalNFT = OriginalNFT(nfts[tokenId].contractAddress);
        string memory originalURI = originalNFT.tokenURI(nfts[tokenId].tokenId);
        return originalURI;
    }

    receive() external payable {}

    function withdraw() public {
        require(msg.sender == owner && address(this).balance > 0);
        payable(owner).transfer(address(this).balance);
    }
}

contract OriginalNFT {
    function ownerOf(uint256) public view returns (address) {}
    function tokenURI(uint256) public view returns (string memory) {}
    function totalSupply() public view returns (uint256) {}
}
