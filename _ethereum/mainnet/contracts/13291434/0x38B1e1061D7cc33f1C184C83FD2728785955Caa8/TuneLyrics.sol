// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./IERC721Enumerable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";

contract TuneLyrics is ERC721, ERC721URIStorage, Ownable {
    using Strings for uint256;
    IERC721Enumerable public tunes;
    string private _tokenBaseURI;
    uint256 public constant PRICE = 0.01 ether;

    bool public frozen = false;

    constructor(address tunesOfficialAddress) ERC721("TuneLyrics", "TLYRIC") {
        tunes = IERC721Enumerable(tunesOfficialAddress);
    }

    function _baseURI() internal view override returns (string memory) {
        return _tokenBaseURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        require(!frozen, "Contract is frozen.");

        _tokenBaseURI = baseURI;
    }

    function freezeBaseURI() public onlyOwner {
        frozen = true;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function mintPublic(uint256[] calldata tokenIds) public payable {
        require(
            PRICE <= msg.value,
            "Unable to mint, because ETH amount is not sufficient."
        );
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];

            require(
                tokenId > 0 && tokenId <= tunes.totalSupply(),
                "You cannot mint outside of the IDs of Tunes."
            );
            require(
                tunes.ownerOf(tokenId) == msg.sender,
                "You must own the corresponding Tune to mint this."
            );
        }

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            _safeMint(msg.sender, tokenId);
        }
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        string memory baseURI = _baseURI();

        if (bytes(baseURI).length > 0) {
            return string(abi.encodePacked(baseURI, tokenId.toString()));
        }

        return "";
    }
}
