// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Ownable.sol";

contract ArtIsUtility is ERC721, Ownable {
    constructor() ERC721("Art Is Utility", "") {}

    string public svgImageData;
    string public svgImageDataURI;
    string public tokenMetadata;
    string public creator = "Demosthenes.eth";
    string private contractMetadata;
    uint supply;
    bool public frozen = false;

    modifier notFrozen {
        require(frozen == false, "Metadata Is Permanently Frozen");
        _;
    }

    function _baseURI() internal view override returns (string memory) {
        return tokenMetadata;
    }

    function setContractURI(string calldata newContractURI) public onlyOwner {
        contractMetadata = newContractURI;
    }

    function contractURI() public view returns (string memory) {
        return contractMetadata;
    } 

    function freezeMetadata() public onlyOwner notFrozen {
        frozen = true;
    }

    function setMetadata(string calldata newMetadata) public onlyOwner notFrozen {
        tokenMetadata = newMetadata;
        _baseURI();
    }

    function setSVGImageData(string calldata newSVGImageData) public onlyOwner notFrozen {
        svgImageData = newSVGImageData;
    }

    function setSVGImageDataURI(string calldata newSVGURI) public onlyOwner notFrozen {
        svgImageDataURI = newSVGURI;
    }

    function mint(address to, uint256 tokenId) public onlyOwner {
        require(supply == 0, "Max Supply");
        supply++;
        _mint(to, tokenId);
    }
}