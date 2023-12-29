pragma solidity ^0.8.6;

import "./Ownable.sol";
import "./ERC721.sol";

contract LensFiniLondon is Ownable, ERC721 {
    uint256 private nextTokenId;
    string public baseURI = "https://api-public.finiliar.com/lens-fini-london/";
    string public contractURI = "https://api-public.finiliar.com/lens-fini-contract/";

    constructor()
      ERC721("LensFiniLondon", "LFL")
    {}

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function setContractURI(string memory newContractURI) external onlyOwner {
        contractURI = newContractURI;
    }

    function adminMint(address to) external onlyOwner {
        _safeMint(to, nextTokenId++);
    }
}