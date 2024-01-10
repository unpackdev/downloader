pragma solidity ^0.8.4;

import "./ERC721Tradable.sol";

contract DesaVillage is ERC721Tradable {
    using Counters for Counters.Counter;

    string public tokenMutableMetadataURI;
    string public contractMetadataURI;

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        address _proxyRegistry
    )
        ERC721Tradable(_tokenName, _tokenSymbol, _proxyRegistry) {}

    function contractURI() public view returns (string memory) {
        return contractMetadataURI;
    }

    function baseTokenURI() override public view returns (string memory) {
        return tokenMutableMetadataURI;
    }

    function setContractMetadata(string memory _contractMetadataURI) public onlyOwner {
        contractMetadataURI = _contractMetadataURI;
    }

    function setTokenMutableMetadata(string memory _tokenMutableMetadataURI) public onlyOwner {
        tokenMutableMetadataURI = _tokenMutableMetadataURI;
    }

    function mint() public onlyOwner {
        uint256 tokenId = _nextTokenId.current();
        
        _safeMint(msg.sender, tokenId);
        
        _nextTokenId.increment();
    }
}