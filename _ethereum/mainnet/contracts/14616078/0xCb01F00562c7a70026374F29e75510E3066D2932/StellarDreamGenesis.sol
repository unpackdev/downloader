// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./ERC721A.sol";
import "./Ownable.sol";

// ███████╗████████╗███████╗██╗     ██╗      █████╗ ██████╗     ██████╗ ██████╗ ███████╗ █████╗ ███╗   ███╗
// ██╔════╝╚══██╔══╝██╔════╝██║     ██║     ██╔══██╗██╔══██╗    ██╔══██╗██╔══██╗██╔════╝██╔══██╗████╗ ████║
// ███████╗   ██║   █████╗  ██║     ██║     ███████║██████╔╝    ██║  ██║██████╔╝█████╗  ███████║██╔████╔██║
// ╚════██║   ██║   ██╔══╝  ██║     ██║     ██╔══██║██╔══██╗    ██║  ██║██╔══██╗██╔══╝  ██╔══██║██║╚██╔╝██║
// ███████║   ██║   ███████╗███████╗███████╗██║  ██║██║  ██║    ██████╔╝██║  ██║███████╗██║  ██║██║ ╚═╝ ██║
// ╚══════╝   ╚═╝   ╚══════╝╚══════╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝

//              ██████╗  ██████╗ ██████╗       ██╗     ███████╗██╗   ██╗███████╗██╗
//             ██╔════╝ ██╔═══██╗██╔══██╗      ██║     ██╔════╝██║   ██║██╔════╝██║
//             ██║  ███╗██║   ██║██║  ██║█████╗██║     █████╗  ██║   ██║█████╗  ██║
//             ██║   ██║██║   ██║██║  ██║╚════╝██║     ██╔══╝  ╚██╗ ██╔╝██╔══╝  ██║
//             ╚██████╔╝╚██████╔╝██████╔╝      ███████╗███████╗ ╚████╔╝ ███████╗███████╗
//              ╚═════╝  ╚═════╝ ╚═════╝       ╚══════╝╚══════╝  ╚═══╝  ╚══════╝╚══════╝

contract StellarDreamGenesis is ERC721A, Ownable {
    uint256 public GENESIS_MAX = 100;

    bool public activated;

    bool public metadataLocked;

    string public unrevealedTokenURI;

    mapping(uint256 => string) private _tokenURIs;

    constructor(string memory name, string memory symbol) ERC721A(name, symbol) {
    }

    ////  OVERIDES
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        //  Check if a string present in the mapping - i.e. if the URI has been set for this token
        bytes memory uri = bytes(_tokenURIs[tokenId]);
        if (uri.length > 0) {
            return _tokenURIs[tokenId];
        } else {
            return unrevealedTokenURI;
        }
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    ////  MINT
    function mintOwner(uint256 numberOfTokens) external onlyOwner {
        require(activated, 'Inactive');
        require(totalSupply() + numberOfTokens <= GENESIS_MAX, 'All minted');
        _safeMint(msg.sender, numberOfTokens);
    }

    ////  SETTERS
    function setUnrevealedTokenUri(string calldata newURI) external onlyOwner {
        unrevealedTokenURI = newURI;
    }

    //  Each token will be created as 1/1 and at different times. Therefore the token URI needs to be unique per token and be able to be set individually
    function setTokenURI(uint256 tokenId, string calldata newURI) external onlyOwner {
        require(!metadataLocked, 'Metadata is locked, unable to change');
        _tokenURIs[tokenId] = newURI;
    }

    function setTokenURIs(uint256[] calldata tokenIds, string[] calldata newURIs) external onlyOwner {
        require(!metadataLocked, 'Metadata is locked, unable to change');
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _tokenURIs[tokenIds[i]] = newURIs[i];
        }
    }

    function setIsActive(bool _isActive) external onlyOwner {
        activated = _isActive;
    }

    function setMetadataLocked() external onlyOwner {
        metadataLocked = true;
    }

    ////  WITHDRAW
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}
