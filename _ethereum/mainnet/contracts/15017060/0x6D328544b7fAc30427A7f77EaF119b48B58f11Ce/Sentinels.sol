// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Ownable.sol";

/// @custom:security-contact chrisdotn@laidback.ventures
contract Sentinels is ERC721, Ownable {

    uint256 public numberOfTokens;
    string internal metadataBaseUrl;
    bool private frozen;

    event PermanentURI(string _value, uint256 indexed _id);

    modifier onlyNotFrozen() {
        require(!frozen, "Contract frozen, no changes possible");
        _;
    }

    constructor(address _artist, string memory _ipfsHash, uint256 _numberOfArtworks) ERC721("Sentinels", "SNTL") {
        numberOfTokens = 0;
        metadataBaseUrl = string(abi.encodePacked("ipfs://", _ipfsHash, "/"));
        frozen = false;

        for (uint256 tokenId = 1; tokenId < _numberOfArtworks + 1; tokenId++) {
            _mint(_artist, tokenId);
        }
        numberOfTokens += _numberOfArtworks;

    }

    function setMetadataBaseUrl(string memory _ipfsHash) external onlyOwner onlyNotFrozen {
        metadataBaseUrl = string(abi.encodePacked("ipfs://", _ipfsHash, "/"));
    }

    function freeze() external onlyOwner {
        frozen = true;

        for (uint256 i=1; i < 13; i++) {
            emit PermanentURI(tokenURI(i), i);
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return metadataBaseUrl;
    }

    function safeMint(address to, uint256 tokenId) public onlyOwner onlyNotFrozen{
        _safeMint(to, tokenId);
        numberOfTokens++;
    }

    function burn(uint256 _tokenId) public {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), _tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(_tokenId);
        numberOfTokens--;
    } 

    function totalSupply() public view returns (uint256) {
        return numberOfTokens;
    }
}
